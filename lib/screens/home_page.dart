import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:waketogether/screens/requests.dart';
import 'package:collection/collection.dart';

import '../services/notification_service.dart';
import '../data/AlarmItem.dart';
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
  static StreamSubscription<QuerySnapshot>? alarmStateSubscription;
  bool hasRequest = false;

  @override
  void initState() {
    super.initState();
    listenForUpdates();
    _requestListener();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
    checkAndRequestPermissions();
    // Bildirim servisini başlat ve callback'i ayarla
    NotificationService.onNotificationTap = (String? payload) {
      if (payload == "requests_page") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RequestsPage()),
        );
      }
    };
    NotificationService.initialize();
    _setupAlarmStateListener();

    // İlk açılışta bildirimden gelip gelmediğini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = NotificationService.checkAndClearPayload();
      if (payload == "requests_page") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RequestsPage()),
        );
      }
    });
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

  void _requestListener() {
    final firestore = FirebaseFirestore.instance;
    final userEmail = FirebaseAuth.instance.currentUser!.email!;

    firestore
        .collection('requests')
        .where('to', isEqualTo: userEmail)
        .where('isAccepted', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      final newHasInvite = snapshot.docs.isNotEmpty;
      if (newHasInvite != hasRequest) {
        setState(() {
          hasRequest = newHasInvite;
        });
      }
    });
  }

  void _setupAlarmStateListener() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    // Giden istekler için dinleme
    firestore
        .collection('requests')
        .where('from', isEqualTo: userEmail)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data() as Map<String, dynamic>;
          if (data['isAccepted'] == true) {
            String toEmail = data['to'];
            GeneralUtils.showToastMessage("$toEmail isteğinizi kabul etti!");
            NotificationService.showNotification(
              title: "Harika!",
              body: "$toEmail alarm isteğinizi kabul etti!",
            );
          }
        }
      }
    });

    // Gelen istekler için dinleme
    firestore
        .collection('requests')
        .where('to', isEqualTo: userEmail)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          if (data['isAccepted'] == false) {
            String fromEmail = data['from'];
            _showRequestNotification(fromEmail);
          }
        }
      }
    });
  }

  void _showRequestNotification(String fromEmail) {
    NotificationService.showNotification(
      title: "Yeni Alarm İsteği",
      body: "$fromEmail seninle uyanmak istiyor! Kabul etmek için hemen tıkla!",
      payload: "requests_page", // Bildirime tıklanınca RequestsPage'e yönlendirecek
    );
    GeneralUtils.showToastMessage("$fromEmail size alarm isteği gönderdi!");
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
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    List<AlarmItem> tempAlarms = [];

    final alarmsSnapshot = await firestore
        .collection('alarms')
        .where('AlarmUsers', arrayContains: userEmail)
        .get();

    var previousID = -1;
    for (var doc in alarmsSnapshot.docs) {
      var id = doc['id'];
      if (previousID == -1) {
        previousID = id;
      } else if (previousID == id) {
        continue;
      }

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

      tempAlarms.add(alarm);
    }

    setState(() {
      alarms = tempAlarms.reversed.toList();
    });

    var pluginAlarms = Alarm.getAlarms();
    for (var pluginAlarm in pluginAlarms) {
      AlarmItem? matchedAlarm = alarms.firstWhereOrNull(
            (a) => a.id == pluginAlarm.id,
      );

      if (matchedAlarm != null && matchedAlarm.isActive) {
        _scheduleAlarm(matchedAlarm, false); // matchedAlarm burada alarms listesindekidir
      } else {
        _cancelAlarm(pluginAlarm.id);
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

    setState(() {
      alarms[index] = alarm;
    });

    if (newValue) {
      _scheduleAlarm(alarm, true);
    } else {
      _cancelAlarm(alarm.id!);
    }
  }

  Future<void> _scheduleAlarm(AlarmItem alarm, bool showToast) async {
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
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    // Önce normal alarm ID'si ile kontrol
    var alarmSnapshot = await firestore
        .collection('alarms')
        .where('id', isEqualTo: alarmSettings.id)
        .where('AlarmUsers', arrayContains: userEmail)
        .get();

    // Eğer bulunamazsa snooze ID'si ile kontrol
    if (alarmSnapshot.docs.isEmpty) {
      alarmSnapshot = await firestore
          .collection('alarms')
          .where('id', isEqualTo: alarmSettings.id - 10000)
          .where('AlarmUsers', arrayContains: userEmail)
          .get();
    }
    //TODO : Abi bu işi siktir git generic bir yerde yap amk her seferinde bu dönüşümle uğraşma
    if (alarmSnapshot.docs.isNotEmpty) {
      var doc = alarmSnapshot.docs.first;
      AlarmItem alarmItem = AlarmItem(
        id: doc['id'],
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

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => AlarmRingScreen(
            alarmSettings: alarmSettings,
            alarmItem: alarmItem,
          ),
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
            icon: Icon(
              hasRequest
                  ? Icons.mark_email_unread
                  : Icons.mark_email_read,
              color: hasRequest
                  ? Colors.red
                  : null,
            ),
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
