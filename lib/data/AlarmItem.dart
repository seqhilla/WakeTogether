const String tableAlarms = 'alarms';

class AlarmFields {
  static final List<String> values = [
    id, name, time, daysActive, isActive, isSingleAlarm
  ];

  static const String id = '_id';
  static const String name = 'name';
  static const String time = 'time';
  static const String daysActive = 'daysActive';
  static const String isActive = 'isActive';
  static const String isSingleAlarm = 'isSingleAlarm';
}

class AlarmItem {
  final int? id;
  final String name;
  final String time;
  final String daysActive; // Consider storing as a JSON string or comma-separated values
  final bool isActive;
  final bool? isSingleAlarm;

  const AlarmItem({
    this.id,
    required this.name,
    required this.time,
    required this.daysActive,
    required this.isActive,
    this.isSingleAlarm,
  });

  AlarmItem copy({
    int? id,
    String? name,
    String? time,
    String? daysActive,
    bool? isActive,
    bool? isSingleAlarm
  }) =>
      AlarmItem(
        id: id ?? this.id,
        name: name ?? this.name,
        time: time ?? this.time,
        daysActive: daysActive ?? this.daysActive,
        isActive: isActive ?? this.isActive,
        isSingleAlarm: isSingleAlarm ?? this.isSingleAlarm
      );

  static AlarmItem fromJson(Map<String, Object?> json) => AlarmItem(
    id: json[AlarmFields.id] as int?,
    name: json[AlarmFields.name] as String,
    time: json[AlarmFields.time] as String,
    daysActive: json[AlarmFields.daysActive] as String,
    isActive: json[AlarmFields.isActive] == 1,
    isSingleAlarm: json[AlarmFields.isSingleAlarm] == 1,
  );

  Map<String, Object?> toJson() => {
    AlarmFields.id: id,
    AlarmFields.name: name,
    AlarmFields.time: time,
    AlarmFields.daysActive: daysActive,
    AlarmFields.isActive: isActive ? 1 : 0,
    AlarmFields.isSingleAlarm: handleIsSingleAlarm(isSingleAlarm),
  };

  int handleIsSingleAlarm(bool? isSingleAlarm) {
    if (isSingleAlarm == true) {
      return 1;
    } else {
      return 0;
    }
  }

}