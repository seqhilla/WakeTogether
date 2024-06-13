import 'package:flutter/material.dart';

import '../data/AlarmItem.dart';

class TimeUtils {
  static String to24hFormat(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static TimeOfDay toTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static DateTime getClosestActiveAlarmDateTime(List<DateTime> dateTimeList) {
    final now = DateTime.now();
    DateTime? dateTimeToReturn;
    if (dateTimeList.length == 1) {
      dateTimeToReturn = dateTimeList[0];
    } else {
      for (var time in dateTimeList) {
        if (dateTimeToReturn == null) {
          dateTimeToReturn = time;
        } else {
          if (time.difference(now).inSeconds <
              dateTimeToReturn.difference(now).inSeconds) {
            dateTimeToReturn = time;
          }
        }
      }
    }

    return dateTimeToReturn!;
  }

  static List<DateTime> getActivaAlarmDateList(AlarmItem alarm) {
    final time = toTimeOfDay(alarm.time);
    final daysActive =
        alarm.daysActive.split(',').map((e) => e == 'true').toList();
    final now = DateTime.now();
    List<DateTime> realAlarmDateTime = [];

    if (alarm.isSingleAlarm == true) {
      DateTime fakeAlarmDate =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (fakeAlarmDate.microsecondsSinceEpoch < now.microsecondsSinceEpoch) {
        DateTime alarmDateTime =
            DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
        realAlarmDateTime.add(alarmDateTime);
      } else {
        realAlarmDateTime.add(fakeAlarmDate);
      }
    } else {
      for (var i = 0; i < daysActive.length; i++) {
        if (daysActive[i] == true) {
          int currentDayOfWeek = now.weekday - 1;
          //TODO: Fix next month and next year issue
          if (i >= currentDayOfWeek) {
            DateTime alarmDateTime = DateTime(now.year, now.month,
                now.day + (i - currentDayOfWeek), time.hour, time.minute);
            if (alarmDateTime.microsecondsSinceEpoch >
                now.microsecondsSinceEpoch) {
              realAlarmDateTime.add(alarmDateTime);
            } else {
              DateTime alarmDateTime = DateTime(now.year, now.month,
                  now.day + (7 - currentDayOfWeek + i), time.hour, time.minute);
              realAlarmDateTime.add(alarmDateTime);
            }
          } else {
            //TODO: check maybe Not usefull at all
            DateTime alarmDateTime = DateTime(now.year, now.month,
                now.day + (7 - currentDayOfWeek + i), time.hour, time.minute);
            realAlarmDateTime.add(alarmDateTime);
          }
        }
      }
    }
    return realAlarmDateTime;
  }

  static DateTime getClosestDateTimeInAlarm(AlarmItem alarm) {
    List<DateTime> realAlarmDateTime = getActivaAlarmDateList(alarm);
    return getClosestActiveAlarmDateTime(realAlarmDateTime);
  }

  static String getDayName(int day) {
    switch (day) {
      case 1:
        return 'Pazartesi';
      case 2:
        return 'Salı';
      case 3:
        return 'Çarşamba';
      case 4:
        return 'Perşembe';
      case 5:
        return 'Cuma';
      case 6:
        return 'Cumartesi';
      case 7:
        return 'Pazar';
      default:
        return '';
    }
  }

  static String getShortDayName(int day) {
    switch (day) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cts';
      case 7:
        return 'Paz';
      default:
        return '';
    }
  }

  static String getMonthName(int month) {
    switch (month) {
      case 1:
        return "Ocak";
      case 2:
        return "Şubat";
      case 3:
        return "Mart";
      case 4:
        return "Nisan";
      case 5:
        return "Mayıs";
      case 6:
        return "Haziran";
      case 7:
        return "Temmuz";
      case 8:
        return "Ağustos";
      case 9:
        return "Eylül";
      case 10:
        return "Ekim";
      case 11:
        return "Kasım";
      case 12:
        return "Aralık";
      default:
        return "";
    }
  }

  static String getShortMonthName(int month) {
    switch (month) {
      case 1:
        return "Oca";
      case 2:
        return "Şub";
      case 3:
        return "Mar";
      case 4:
        return "Nis";
      case 5:
        return "May";
      case 6:
        return "Haz";
      case 7:
        return "Tem";
      case 8:
        return "Ağu";
      case 9:
        return "Eyl";
      case 10:
        return "Eki";
      case 11:
        return "Kas";
      case 12:
        return "Ara";
      default:
        return "";
    }
  }

  static String getHowManyTimeFromNow(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inSeconds < 60) {
      return 'Alarm şu andan itibaren 1 dakika sonraya ayarlandı';
    } else if (difference.inMinutes < 60) {
      return 'Alarm ${difference.inMinutes} dakika sonrasına ayarlandı';
    } else if (difference.inHours < 24) {
      return 'Alarm ${difference.inHours} saat ve ${difference.inMinutes % 60} dakika sonrasına ayarlandı';
    } else {
      return 'Alarm, ${normalizeTime(dateTime.hour)}:${normalizeTime(dateTime.minute)} saati, ${getDayName(dateTime.weekday)}, ${normalizeTime(dateTime.day)} ${getMonthName(dateTime.month)} tarihine ayarlandı';
    }
  }

  static String normalizeTime(int time) {
    if (time < 10) {
      return "0$time";
    } else {
      return time.toString();
    }
  }

  static toDateTimeFromTimeOfDay(TimeOfDay time) {
    return DateTime(0, 0, 0, time.hour, time.minute);
  }

  static toDateTimeFromString(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  static toTimeOfDayFromDateTime(DateTime time) {
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }

  static String getDayMonth(DateTime dateTime) {
    return '${getDayName(dateTime.weekday)}, ${dateTime.day} ${getShortMonthName(dateTime.month)}';
  }
}
