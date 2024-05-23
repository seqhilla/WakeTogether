const String tableAlarms = 'alarms';

class AlarmFields {
  static final List<String> values = [
    id, name, time, daysActive, isActive,
  ];

  static const String id = '_id';
  static const String name = 'name';
  static const String time = 'time';
  static const String daysActive = 'daysActive';
  static const String isActive = 'isActive';
}

class AlarmItem {
  final int? id;
  final String name;
  final String time;
  final String daysActive; // Consider storing as a JSON string or comma-separated values
  final bool isActive;

  const AlarmItem({
    this.id,
    required this.name,
    required this.time,
    required this.daysActive,
    required this.isActive,
  });

  AlarmItem copy({
    int? id,
    String? name,
    String? time,
    String? daysActive,
    bool? isActive,
  }) =>
      AlarmItem(
        id: id ?? this.id,
        name: name ?? this.name,
        time: time ?? this.time,
        daysActive: daysActive ?? this.daysActive,
        isActive: isActive ?? this.isActive,
      );

  static AlarmItem fromJson(Map<String, Object?> json) => AlarmItem(
    id: json[AlarmFields.id] as int?,
    name: json[AlarmFields.name] as String,
    time: json[AlarmFields.time] as String,
    daysActive: json[AlarmFields.daysActive] as String,
    isActive: json[AlarmFields.isActive] == 1,
  );

  Map<String, Object?> toJson() => {
    AlarmFields.id: id,
    AlarmFields.name: name,
    AlarmFields.time: time,
    AlarmFields.daysActive: daysActive,
    AlarmFields.isActive: isActive ? 1 : 0,
  };
}