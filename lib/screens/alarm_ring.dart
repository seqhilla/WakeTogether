import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';
import '../widgets/AlarmCancelButtonWidget.dart';
import '../widgets/ClockWidget.dart';
import 'package:waketogether/utils/GeneralUtils.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;
  final AlarmItem alarmItem;
  bool isCancelled = false; // Yeni değişken

  AlarmRingScreen({
    required this.alarmSettings,
    required this.alarmItem,
    super.key,
  });

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
            ClockWidget(key: UniqueKey(), alarmText: alarmItem.name),
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
                    onSnoozePressed(context, 1); //TODO: For snooze test this should be 5
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
    final now = DateTime.now();
    Alarm.set(
      alarmSettings: alarmSettings.copyWith(
        dateTime: DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(Duration(minutes: minuteToDelay)),
        id: alarmSettings.id < 9999 ? alarmSettings.id + 10000 : alarmSettings.id,
      ),
    );

    safeStopTheAlarm(context);
  }

  void counterToCancel(BuildContext context, int minute) async {
    await Future.delayed(Duration(minutes: minute));
    if (!isCancelled) {
      safeStopTheAlarm(context);
    }
  }

  void safeStopTheAlarm(BuildContext context) {
    isCancelled = true;
    if (alarmItem.isSingleAlarm == true) {
      final alarm = AlarmItem(
          id: alarmItem.id,
          name: alarmItem.name,
          time: alarmItem.time,
          daysActive: alarmItem.daysActive,
          isActive: false,
          isSingleAlarm: alarmItem.isSingleAlarm,
          soundLevel: alarmItem.soundLevel,
          isVibration: alarmItem.isVibration,
          alarmUsers: alarmItem.alarmUsers
      );
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      _firestore.collection('alarms').doc("${alarmItem.alarmUsers[0]}_${alarmItem.id}").update({
        'isActive': false,
      });
      DatabaseHelper.instance.update(alarm);
    }

    Alarm.stop(alarmSettings.id).then((_) => Navigator.pop(context));
  }
}
