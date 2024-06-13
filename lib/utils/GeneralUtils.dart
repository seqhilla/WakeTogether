import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../data/AlarmItem.dart';
import 'TimeUtils.dart';

class GeneralUtils {
  static void showToastMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static void showClosestAlarmToastMessage(AlarmItem alarm) {
    final dateTimeToShow = TimeUtils.getClosestDateTimeInAlarm(alarm);

    showToastMessage(TimeUtils.getHowManyTimeFromNow(dateTimeToShow));
  }
}
