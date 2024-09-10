import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';
import '../data/AlarmRingStates.dart';
import '../widgets/AlarmCancelButtonWidget.dart';
import '../widgets/ClockWidget.dart';
import 'package:waketogether/utils/GeneralUtils.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmItem alarmItem;

  AlarmRingScreen({
    required this.alarmSettings,
    required this.alarmItem,
    super.key,
  });

  @override
  _AlarmRingScreenState createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool isCancelled = false;
  late StreamSubscription<DocumentSnapshot> _subscription;
  List<int> alarmStates = [];

  @override
  void initState() {
    super.initState();
    updateAlarmStateForCurrentUser(0); // Alarm is ringing
    listenForUpdates();
    counterToCancel(context, 50); // TODO: Get from user
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void listenForUpdates() {
    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    _subscription = FirebaseFirestore.instance
        .collection('alarms')
        .doc("${widget.alarmItem.alarmUsers[0]}_${widget.alarmItem.id}")
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          alarmStates = List<int>.from(data['AlarmStates']);
        });
      }
    });
  }

  void updateAlarmStateForCurrentUser(int state) async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    DocumentSnapshot alarmSnapshot = await FirebaseFirestore.instance
        .collection('alarms')
        .doc("${widget.alarmItem.alarmUsers[0]}_${widget.alarmItem.id}")
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
            .doc("${widget.alarmItem.alarmUsers[0]}_${widget.alarmItem.id}")
            .update({'AlarmStates': alarmStates});
      }
    }
  }

  void counterToCancel(BuildContext context, int minute) async {
    await Future.delayed(Duration(minutes: minute));
    if (!isCancelled) {
      safeStopTheAlarm(context);
    }
  }

  void safeStopTheAlarm(BuildContext context) {
    updateAlarmStateForCurrentUser(2); // Alarm is stopped
    isCancelled = true;
    if (widget.alarmItem.isSingleAlarm == true) {
      final alarm = AlarmItem(
          id: widget.alarmItem.id,
          name: widget.alarmItem.name,
          time: widget.alarmItem.time,
          daysActive: widget.alarmItem.daysActive,
          isActive: false,
          isSingleAlarm: widget.alarmItem.isSingleAlarm,
          soundLevel: widget.alarmItem.soundLevel,
          isVibration: widget.alarmItem.isVibration,
          alarmUsers: widget.alarmItem.alarmUsers,
          alarmStates: widget.alarmItem.alarmStates
      );
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      _firestore.collection('alarms').doc("${widget.alarmItem.alarmUsers[0]}_${widget.alarmItem.id}").update({
        'isActive': false,
      });
      DatabaseHelper.instance.update(alarm);
    }

    Alarm.stop(widget.alarmSettings.id).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final res = GeneralUtils.resources(context);
    counterToCancel(
        context, 3); //TODO: Get from user
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            ClockWidget(key: UniqueKey(), alarmText: widget.alarmItem.name),
            const SizedBox(height: 10),
            // Fetch and display other users' emails and states
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('alarms')
                  .doc("${widget.alarmItem.alarmUsers[0]}_${widget.alarmItem.id}")
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('No data found');
                }
                Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
                if (data == null) {
                  return const Text('No data found');
                }
                List<String> alarmUsers = List<String>.from(data['AlarmUsers']);
                String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

                return Column(
                  children: List.generate(alarmUsers.length, (index) {
                    if (alarmUsers[index] == currentUserEmail) {
                      return Container(); // Skip current user's email
                    }
                    String email = alarmUsers[index];
                    int stateValue = alarmStates.isNotEmpty ? alarmStates[index] : 0;
                    AlarmState state = getAlarmStateFromInt(stateValue);
                    String stateMessage = getAlarmStateMessage(state);
                    return Text('$email: $stateMessage');
                  }),
                );
              },
            ),
            const SizedBox(height: 80),
            SizedBox(
                height: 300,
                width: 300,
                child: PullAwayCancelWidget(onCancel: () {
                  safeStopTheAlarm(context);
                })),
            Text(res.snooze,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 1); // TODO: For snooze test this should be 5
                  },
                  child: Text(
                    res.one_min,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 10);
                  },
                  child: Text(
                    res.ten_min,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 15);
                  },
                  child: Text(
                    res.fifteen_min,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 30);
                  },
                  child: Text(
                    res.thirty_min,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onSnoozePressed(BuildContext context, int minuteToDelay) {
    updateAlarmStateForCurrentUser(1); // Alarm is snoozed
    final now = DateTime.now();
    Alarm.set(
      alarmSettings: widget.alarmSettings.copyWith(
        dateTime: DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(Duration(minutes: minuteToDelay)),
        id: widget.alarmSettings.id < 9999 ? widget.alarmSettings.id + 10000 : widget.alarmSettings.id,
      ),
    );

    safeStopTheAlarm(context);
  }
}