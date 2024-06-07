import 'package:flutter/material.dart';

import '../data/AlarmItem.dart';
import '../screens/edit_alarm_screen.dart';

Widget alarmListItem({
  required BuildContext context,
  required AlarmItem alarmItem,
  required Function(bool) onToggle,
  required Function onClickCallBack,
}) {
  const PASSIVE_ANIMATION_DURATION = 300;
  List<bool> daysActiveMap = alarmItem.daysActive.split(',').map((e) => e == 'true').toList();

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
                    if (alarmItem.name.isNotEmpty) AnimatedOpacity(
                      opacity: alarmItem.isActive ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                      child: Text(
                        alarmItem.name,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: alarmItem.isActive ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                      child: Text(alarmItem.time, style: const TextStyle(fontSize: 42)),
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
                          opacity: alarmItem.isActive ? 1.0 : 0.5,
                          duration: const Duration(milliseconds: PASSIVE_ANIMATION_DURATION),
                          child: Container(
                            width: 10,
                            height: 5,
                            decoration: BoxDecoration(
                              color: daysActiveMap[dayIndex] ? Colors.deepPurple : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: alarmItem.isActive ? 1.0 : 0.5,
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