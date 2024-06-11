const String tableAlarms = 'alarms';

class AlarmFields {
  static final List<String> values = [
    id, name, time, daysActive, isActive, isSingleAlarm, soundLevel, isVibration
  ];

  static const String id = '_id';
  static const String name = 'name';
  static const String time = 'time';
  static const String daysActive = 'daysActive';
  static const String isActive = 'isActive';
  static const String isSingleAlarm = 'isSingleAlarm';
  static const String soundLevel = 'soundLevel';
  static const String isVibration = 'isVibration';
}

class AlarmItem {
  final int? id;
  final String name;
  final String time;
  final String daysActive;
  final bool isActive;
  final bool? isSingleAlarm;
  final int soundLevel;
  final bool isVibration;

  const AlarmItem({
    this.id,
    required this.name,
    required this.time,
    required this.daysActive,
    required this.isActive,
    this.isSingleAlarm,
    required this.soundLevel,
    required this.isVibration,
  });

  AlarmItem copy({
    int? id,
    String? name,
    String? time,
    String? daysActive,
    bool? isActive,
    bool? isSingleAlarm,
    int? soundLevel,
    bool? isVibration
  }) =>
      AlarmItem(
          id: id ?? this.id,
          name: name ?? this.name,
          time: time ?? this.time,
          daysActive: daysActive ?? this.daysActive,
          isActive: isActive ?? this.isActive,
          isSingleAlarm: isSingleAlarm ?? this.isSingleAlarm,
          soundLevel: soundLevel ?? this.soundLevel,
          isVibration: isVibration ?? this.isVibration
      );

  static AlarmItem fromJson(Map<String, Object?> json) => AlarmItem(
    id: json[AlarmFields.id] as int?,
    name: json[AlarmFields.name] as String,
    time: json[AlarmFields.time] as String,
    daysActive: json[AlarmFields.daysActive] as String,
    isActive: json[AlarmFields.isActive] == 1,
    isSingleAlarm: json[AlarmFields.isSingleAlarm] == 1,
    soundLevel: json[AlarmFields.soundLevel] as int,
    isVibration: json[AlarmFields.isVibration] == 1,
  );

  Map<String, Object?> toJson() => {
    AlarmFields.id: id,
    AlarmFields.name: name,
    AlarmFields.time: time,
    AlarmFields.daysActive: daysActive,
    AlarmFields.isActive: isActive ? 1 : 0,
    AlarmFields.isSingleAlarm: handleIsSingleAlarm(isSingleAlarm),
    AlarmFields.soundLevel: soundLevel,
    AlarmFields.isVibration: isVibration ? 1 : 0,
  };

  int handleIsSingleAlarm(bool? isSingleAlarm) {
    if (isSingleAlarm == true) {
      return 1;
    } else {
      return 0;
    }
  }

}