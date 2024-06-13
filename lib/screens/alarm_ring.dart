import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';
import '../widgets/AlarmCancelButtonWidget.dart';
import '../widgets/ClockWidget.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;
  final AlarmItem alarmItem;

  const AlarmRingScreen({
    required this.alarmSettings,
    required this.alarmItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    counterToCancel(
        context, 66); //TODO: 3 falan olabilir karar ver şimdilik yüksek
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
            Text("Şu kadar ertele:",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 1);
                  },
                  child: Text(
                    '1 Dk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 10);
                  },
                  child: Text(
                    '10 Dk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 15);
                  },
                  child: Text(
                    '15 Dk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    onSnoozePressed(context, 30);
                  },
                  child: Text(
                    '30 Dk',
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
    final now = DateTime.now(); //TODO: Ötüyor fakat görünmez :(
    Alarm.set(
      alarmSettings: alarmSettings.copyWith(
        dateTime: DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(Duration(minutes: minuteToDelay)),
        id: alarmSettings.id + 10000,
      ),
    );

    safeStopTheAlarm(context);
  }

  void counterToCancel(BuildContext context, int minute) async {
    await Future.delayed(Duration(minutes: minute));
    if (Navigator.of(context).canPop()) {
      safeStopTheAlarm(context);
    }
  }

  void safeStopTheAlarm(BuildContext context) {
    if (alarmItem.isSingleAlarm == true) {
      final alarm = AlarmItem(
          id: alarmItem.id,
          name: alarmItem.name,
          time: alarmItem.time,
          daysActive: alarmItem.daysActive,
          isActive: false,
          isSingleAlarm: alarmItem.isSingleAlarm,
          soundLevel: alarmItem.soundLevel,
          isVibration: alarmItem.isVibration);
      DatabaseHelper.instance.update(alarm);
    }

    Alarm.stop(alarmSettings.id).then((_) => Navigator.pop(context));
  }
}
