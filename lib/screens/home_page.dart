import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/AlarmItem.dart';
import '../utils/DatabaseHelper.dart';
import '../utils/GeneralUtils.dart';
import '../utils/TimeUtils.dart';
import '../widgets/alarm_card.dart';
import 'alarm_ring.dart';
import 'edit_alarm_screen.dart';

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
    checkAndRequestPermissions();
  }

  Future<void> checkAndRequestPermissions() async {
    List<Permission> permissions = [
      Permission.ignoreBatteryOptimizations,
      Permission.scheduleExactAlarm,
      Permission.notification
    ];

    for (var permission in permissions) {
      var status = await permission.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        print('Requesting $permission permission...');
        var res = await permission.request();
        print('$permission permission ${res.isGranted ? '' : 'not'} granted.');
      }
    }
  }

  void _loadAlarms() async {
    final dbAlarms = await DatabaseHelper.instance.readAllAlarms();
    setState(() {
      alarms = dbAlarms.reversed.toList();
    });
    for (var alarm in alarms) {
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
        daysActive: alarms[index].daysActive,
        isActive: newValue,
        isSingleAlarm: alarms[index].isSingleAlarm,
        soundLevel: alarms[index].soundLevel,
        isVibration: alarms[index].isVibration);

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
      dateTime: alarmDateTimeToSet,
      assetAudioPath: 'assets/alarm.mp3',
      //TODO: Get From user
      loopAudio: true,
      vibrate: alarm.isVibration,
      volume: alarm.soundLevel.toDouble(),
      fadeDuration: 3.0,
      notificationTitle: "Alarm Çalıyor",
      notificationBody: alarm.name,
      //TODO: Fix
      enableNotificationOnKill: true,
    );

    if (isFromToggle) {
      showClosestAlarmToastMessage(alarm);
    }

    await Alarm.set(alarmSettings: alarmSettings);
  }

  void _cancelAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    AlarmItem? alarmItem =
        await DatabaseHelper.instance.findAlarmItem(alarmSettings.id);
    if (alarmItem != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => AlarmRingScreen(
              alarmSettings: alarmSettings, alarmItem: alarmItem),
        ),
      );
      _loadAlarms();
    }
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
                    initialAlarm: AlarmItem(
                        name: '',
                        time: "06:00",
                        daysActive: '0,0,0,0,0,0,0',
                        isActive: true,
                        isSingleAlarm: true,
                        soundLevel: 80,
                        isVibration: true),
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
              onToggle: (newValue) => _toggleActive(index, newValue),
              context: context,
              alarmItem: alarm,
              onClickCallBack: _loadAlarms,
            ),
          );
        },
      ),
    );
  }
}
