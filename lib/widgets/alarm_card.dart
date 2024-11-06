import 'package:flutter/material.dart';

import '../data/AlarmItem.dart';
import '../screens/edit_alarm_screen.dart';
import '../utils/TimeUtils.dart';

Widget alarmListItem({
  required BuildContext context,
  required AlarmItem alarmItem,
  required Function(bool) onToggle,
  required Function onClickCallBack,
}) {
  const passiveAnimationDuration = 300;
  List<bool> daysActiveMap =
      alarmItem.daysActive.split(',').map((e) => e == 'true').toList();

  return GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditAlarmScreen(
            initialAlarm: alarmItem,
            isNew: false,
          ),
        ),
      );
      if (result != null) {
        await onClickCallBack();
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
            offset: const Offset(0, 4),
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
                    if (alarmItem.name.isNotEmpty)
                      AnimatedOpacity(
                        opacity: alarmItem.isActive ? 1.0 : 0.5,
                        duration: const Duration(
                            milliseconds: passiveAnimationDuration),
                        child: Text(
                          alarmItem.name,
                          style: alarmItem.name.length <= 15
                              ? const TextStyle(fontSize: 16)
                              : const TextStyle(fontSize: 10),
                          maxLines: alarmItem.name.length <= 15 ? 1 : 2,
                        ),
                      ),
                    AnimatedOpacity(
                      opacity: alarmItem.isActive ? 1.0 : 0.5,
                      duration: const Duration(
                          milliseconds: passiveAnimationDuration),
                      child: Text(alarmItem.time,
                          style: const TextStyle(fontSize: 42)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Visibility(
                visible: alarmItem.isSingleAlarm == false,
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: alarmItem.isActive ? 1.0 : 0.5,
                            duration: const Duration(
                                milliseconds: passiveAnimationDuration),
                            child: Container(
                              width: 10,
                              height: 5,
                              decoration: BoxDecoration(
                                color: daysActiveMap[dayIndex]
                                    ? Colors.deepPurple
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: alarmItem.isActive ? 1.0 : 0.5,
                            duration: const Duration(
                                milliseconds: passiveAnimationDuration),
                            child: Text(
                                ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][dayIndex],
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Visibility(
                  visible: alarmItem.isSingleAlarm == true,
                  child: AnimatedOpacity(
                    opacity: alarmItem.isActive ? 1.0 : 0.5,
                    duration: const Duration(
                        milliseconds: passiveAnimationDuration),
                    child: Text(
                        TimeUtils.getDayMonth(
                            TimeUtils.getClosestDateTimeInAlarm(alarmItem)),
                        style: const TextStyle(fontSize: 12)),
                  )),
              const SizedBox(width: 16),
              Switch(
                value: alarmItem.isActive,
                onChanged: onToggle,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
