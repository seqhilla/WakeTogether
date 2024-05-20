import 'package:flutter/material.dart';

String to24hFormat(TimeOfDay time) {
  final hours = time.hour.toString().padLeft(2, '0');
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

TimeOfDay toTimeOfDay(String time) {
  final parts = time.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
