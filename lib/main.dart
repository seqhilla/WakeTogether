import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/screens/alarm_ring.dart';
import 'package:waketogether/screens/edit_alarm_screen.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';
import 'package:waketogether/utils/GeneralUtils.dart';
import 'package:waketogether/utils/TimeUtils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeTogether',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WakeTogether'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AlarmItem> alarms = [];

  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  void _loadAlarms() async {
    final dbAlarms = await DatabaseHelper.instance.readAllAlarms();
    setState(() {
      alarms = dbAlarms.reversed.toList();
    });

    for(var alarm in alarms) {
      if (alarm.isActive) {
        _scheduleAlarm(alarm, false);
      } else {
        _cancelAlarm(alarm.id!);
      }
    }

  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void _toggleActive(int index, bool newValue) async {
    final alarm = AlarmItem(
      id: alarms[index].id,
      name: alarms[index].name,
      time: alarms[index].time,
      daysActive:alarms[index].daysActive,
      isActive: newValue,
    );

    await DatabaseHelper.instance.update(alarm);
    setState(() {
      alarms[index] = alarm;
    });

    if (newValue) {
      _scheduleAlarm(alarm, true);
    } else {
      _cancelAlarm(alarm.id!);
    }

  }

  Future<void> _scheduleAlarm(AlarmItem alarm, bool isFromToggle) async {
    final alarmDateTimeToSet = getClosestDateTimeInAlarm(alarm);

    final alarmSettings = AlarmSettings(
      id: alarm.id!,
      dateTime: alarmDateTimeToSet!,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationTitle: alarm.name,
      notificationBody: 'This is the body',
      enableNotificationOnKill: true,
    );

    if(isFromToggle) {
      showClosestAlarmToastMessage(alarm);
    }

    await Alarm.set(alarmSettings: alarmSettings);
  }

  void _cancelAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            ExampleAlarmRingScreen(alarmSettings: alarmSettings),
      ),
    );
    _loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditAlarmScreen(
                    initialAlarm: AlarmItem(name: '', time: "06:00", daysActive: '0,0,0,0,0,0,0', isActive: true),
                    isNew: true,
                  ),
                ),
              );
              if (result != null) {
                _loadAlarms(); // Reload alarms from database
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: alarmListItem(
              alarmName: alarm.name,
              alarmTime: toTimeOfDay(alarm.time),
              daysActive: alarm.daysActive.split(',').map((e) => e == 'true').toList(),
              isActive: alarm.isActive,
              onToggle: (newValue) => _toggleActive(index, newValue),
              context: context,
              index: index,
            ),
          );
        },
      ),
    );
  }

  Widget alarmListItem({
    required String alarmName,
    required TimeOfDay alarmTime,
    required List<bool> daysActive,
    required bool isActive,
    required Function(bool) onToggle,
    required BuildContext context,
    required int index,
  }) {
    const PASSIVE_ANIMATION_DURATION = 300;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAlarmScreen(
              initialAlarm: alarms[index],
              isNew: false,
            ),
          ),
        );
        if (result != null) {
          _loadAlarms(); // Reload alarms from database
        }
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alarmName.isNotEmpty) AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                        child: Text(
                          alarmName,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                        child: Text(to24hFormat(alarmTime), style: const TextStyle(fontSize: 42)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  children: List.generate(7, (dayIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: isActive ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                            child: Container(
                              width: 10,
                              height: 5,
                              decoration: BoxDecoration(
                                color: daysActive[dayIndex] ? Colors.deepPurple : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: isActive ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                            child: Text(['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][dayIndex], style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: isActive,
                  onChanged: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}