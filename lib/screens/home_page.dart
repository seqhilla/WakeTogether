import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:waketogether/screens/requests.dart';

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
    //_loadAlarms();
    listenForUpdates();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
    checkAndRequestPermissions();
  }

  void listenForUpdates() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    String userEmail = auth.currentUser!.email!;

    firestore
        .collection('alarms')
        .where('AlarmUsers', arrayContains: userEmail)
        .snapshots()
        .listen((snapshot) {
      // If an update is detected, call the _loadAlarms function
      _loadAlarms();
    });
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
    print('Loading alarms...');
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get the email of the current user
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    await DatabaseHelper.instance.deleteAll();

    final alarmsSnapshot = await firestore
        .collection('alarms')
        .where('AlarmUsers', arrayContains: userEmail)
        .get();
    var previousID = -1;
    for (var doc in alarmsSnapshot.docs) {
      var id = doc['id'];
      if (previousID == -1) {
        previousID = id;
        print("Hello");
      } else if (previousID == id) {
        print("FROM");
        continue;
      }
      print("ALARMALARM");
      AlarmItem alarm = AlarmItem(
        id: id,
        name: doc['name'],
        time: doc['time'],
        daysActive: doc['daysActive'],
        isActive: doc['isActive'],
        isSingleAlarm: doc['isSingleAlarm'],
        soundLevel: doc['soundLevel'],
        isVibration: doc['isVibration'],
        alarmUsers: listToString(doc['AlarmUsers']),
        alarmStates: listToInt(doc['AlarmStates']),
      );
      await DatabaseHelper.instance.create(alarm);
    }

    final dbAlarms = await DatabaseHelper.instance.readAllAlarms();
    setState(() {
      alarms = dbAlarms.reversed.toList();
    });

    for(var alarm in alarms) {
      if (alarm.isActive) {
        print("Hasasn");
        _scheduleAlarm(alarm, false);
      } else {
        _cancelAlarm(alarm.id!);
      }
    }
  }

  List<String> listToString(List<dynamic> list) {
    List<String> result = [];
    for (var item in list) {
      result.add(item.toString());
    }
    return result;
  }

  List<int> listToInt(List<dynamic> list) {
    List<int> result = [];
    for (var item in list) {
      result.add(item as int);
    }
    return result;
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
        isVibration: alarms[index].isVibration,
        alarmUsers: alarms[index].alarmUsers,
        alarmStates: alarms[index].alarmStates
    );

    //firestore'da da güncelle
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore.collection('alarms').doc("${alarms[index].alarmUsers[0]}_${ alarms[index].id}").update({
      'isActive': newValue,
    });

    await DatabaseHelper.instance.update(alarm);
    setState(() {
      alarms[index] = alarm;
    });

    if (newValue) {
      print("gezer");

      _scheduleAlarm(alarm, true);
    } else {
      _cancelAlarm(alarm.id!);
    }
  }

  Future<void> _scheduleAlarm(AlarmItem alarm, bool showToast) async {
    print("EKMEK");
    //updateAlarmStateForCurrentUser(alarm, 3); //Alarm is setted
    final alarmDateTimeToSet = TimeUtils.getClosestDateTimeInAlarm(alarm);

    final alarmSettings = AlarmSettings(
      id: alarm.id!,
      dateTime: alarmDateTimeToSet,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: alarm.isVibration,
      volume: alarm.soundLevel / 100,
      fadeDuration: 3.0,
      notificationTitle: "Alarm Çalıyor",
      notificationBody: alarm.name,
      enableNotificationOnKill: true,
    );

    if (showToast) {
      GeneralUtils.showClosestAlarmToastMessage(alarm);
    }

    await Alarm.set(alarmSettings: alarmSettings);
  }

  void _cancelAlarm(int alarmId) async {
    /*
    AlarmItem? alarmItem =
    await DatabaseHelper.instance.findAlarmItem(alarmId);
    if (alarmItem != null) {
      updateAlarmStateForCurrentUser(alarmItem, 4); //Alarm is cancelled
    }
     */
    await Alarm.stop(alarmId);
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    AlarmItem? alarmItem =
        await DatabaseHelper.instance.findAlarmItem(alarmSettings.id);

    alarmItem ??= await DatabaseHelper.instance.findAlarmItem(alarmSettings.id - 10000); //if from snooze this is gonna work

    if (alarmItem != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => AlarmRingScreen(
              alarmSettings: alarmSettings, alarmItem: alarmItem!),
        ),
      );
      _loadAlarms();
    }
  }

  void updateAlarmStateForCurrentUser(AlarmItem alarmItem, int state) async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    DocumentSnapshot alarmSnapshot = await FirebaseFirestore.instance
        .collection('alarms')
        .doc("${alarmItem.alarmUsers[0]}_${alarmItem.id}")
        .get();

    if (alarmSnapshot.exists) {
      Map<String, dynamic> data = alarmSnapshot.data() as Map<String, dynamic>;
      List<String> alarmUsers = List<String>.from(data['AlarmUsers']);
      List<int> alarmStates = List<int>.from(data['AlarmStates']);

      int userIndex = alarmUsers.indexOf(currentUserEmail);
      if (userIndex != -1) {
        alarmStates[userIndex] = state;

        await FirebaseFirestore.instance
            .collection('alarms')
            .doc("${alarmItem.alarmUsers[0]}_${alarmItem.id}")
            .update({'AlarmStates': alarmStates});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlarms,
          ),
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
                        isVibration: true,
                        alarmUsers: [],
                        alarmStates: []
                    ),
                    isNew: true,
                  ),
                ),
              );
              if (result != null) {
                _loadAlarms(); // Reload alarms from database
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RequestsPage(),
                ),
              );
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
