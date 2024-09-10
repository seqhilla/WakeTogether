enum AlarmState {
  alarmRinging,
  alarmSnoozed,
  alarmStopped,
  alarmSetted,
  alarmCancelled,
  alarmUnknown,
}

AlarmState getAlarmStateFromInt(int value) {
  switch (value) {
    case 0:
      return AlarmState.alarmRinging;
    case 1:
      return AlarmState.alarmSnoozed;
    case 2:
      return AlarmState.alarmStopped;
    case 3:
      return AlarmState.alarmSetted;
    case 4:
      return AlarmState.alarmCancelled;
    case 99:
      return AlarmState.alarmUnknown;
    default:
      throw ArgumentError("Invalid integer value for AlarmState: $value");
  }
}

String getAlarmStateMessage(AlarmState state) {
  switch (state) {
    case AlarmState.alarmRinging:
      return "Alarm is ringing!";
    case AlarmState.alarmSnoozed:
      return "Alarm is snoozed.";
    case AlarmState.alarmStopped:
      return "Alarm is stopped.";
    case AlarmState.alarmSetted:
      return "Alarm is setted.";
    case AlarmState.alarmCancelled:
      return "Alarm is cancelled.";
    case AlarmState.alarmUnknown:
      return "Alarm is unknown.";
    default:
      return "Unknown state.";
  }
}
