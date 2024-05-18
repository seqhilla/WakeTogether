class AlarmItem {
  String alarmName;
  String alarmTime;
  List<bool> daysActive;
  bool isActive;

  AlarmItem({
    required this.alarmName,
    required this.alarmTime,
    required this.daysActive,
    required this.isActive,
  });
}