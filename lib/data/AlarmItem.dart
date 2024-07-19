const String tableAlarms = 'alarms';

class AlarmFields {
  static final List<String> values = [
    id,
    name,
    time,
    daysActive,
    isActive,
    isSingleAlarm,
    soundLevel,
    isVibration,
    alarmUsers
  ];

  static const String id = '_id';
  static const String name = 'name';
  static const String time = 'time';
  static const String daysActive = 'daysActive';
  static const String isActive = 'isActive';
  static const String isSingleAlarm = 'isSingleAlarm';
  static const String soundLevel = 'soundLevel';
  static const String isVibration = 'isVibration';
  static const String alarmUsers = 'alarmUsers';
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
  final List<String> alarmUsers;

  const AlarmItem({
    this.id,
    required this.name,
    required this.time,
    required this.daysActive,
    required this.isActive,
    this.isSingleAlarm,
    required this.soundLevel,
    required this.isVibration,
    required this.alarmUsers,
  });

  AlarmItem copy(
          {int? id,
          String? name,
          String? time,
          String? daysActive,
          bool? isActive,
          bool? isSingleAlarm,
          int? soundLevel,
          bool? isVibration,
          List<String>? alarmUsers}) =>
      AlarmItem(
          id: id ?? this.id,
          name: name ?? this.name,
          time: time ?? this.time,
          daysActive: daysActive ?? this.daysActive,
          isActive: isActive ?? this.isActive,
          isSingleAlarm: isSingleAlarm ?? this.isSingleAlarm,
          soundLevel: soundLevel ?? this.soundLevel,
          isVibration: isVibration ?? this.isVibration,
          alarmUsers: alarmUsers ?? this.alarmUsers);

  static AlarmItem fromJson(Map<String, Object?> json) => AlarmItem(
        id: stringToInt(json[AlarmFields.id] as String) as int?,
        name: json[AlarmFields.name] as String,
        time: json[AlarmFields.time] as String,
        daysActive: json[AlarmFields.daysActive] as String,
        isActive: json[AlarmFields.isActive] == 1,
        isSingleAlarm: json[AlarmFields.isSingleAlarm] == 1,
        soundLevel: stringToInt(json[AlarmFields.soundLevel] as String),
        isVibration: json[AlarmFields.isVibration] == 1,
        alarmUsers: (json[AlarmFields.alarmUsers] as String).split(','),
      );

  static int stringToInt(String numberString) {
    return int.parse(numberString);
  }

  Map<String, Object?> toJson() => {
        AlarmFields.id: id,
        AlarmFields.name: name,
        AlarmFields.time: time,
        AlarmFields.daysActive: daysActive,
        AlarmFields.isActive: isActive ? 1 : 0,
        AlarmFields.isSingleAlarm: handleIsSingleAlarm(isSingleAlarm),
        AlarmFields.soundLevel: soundLevel,
        AlarmFields.isVibration: isVibration ? 1 : 0,
        AlarmFields.alarmUsers: alarmUsers.join(','),
      };

  int handleIsSingleAlarm(bool? isSingleAlarm) {
    if (isSingleAlarm == true) {
      return 1;
    } else {
      return 0;
    }
  }
}
