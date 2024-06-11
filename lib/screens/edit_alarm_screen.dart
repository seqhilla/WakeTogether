import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';
import 'package:waketogether/utils/TimeUtils.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

import '../utils/GeneralUtils.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmItem initialAlarm;
  final bool isNew;

  const EditAlarmScreen({
    super.key,
    required this.initialAlarm,
    required this.isNew,
  });

  @override
  _EditAlarmScreenState createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late TextEditingController _alarmNameController;
  late TimeOfDay _selectedTime;
  late List<bool> _daysActive;
  late int _soundLevel;
  late bool _isVibration;

  @override
  void initState() {
    super.initState();
    _alarmNameController =
        TextEditingController(text: widget.initialAlarm.name);
    _selectedTime = toTimeOfDay(widget.initialAlarm.time);
    _daysActive = widget.initialAlarm.daysActive
        .split(',')
        .map((e) => e == 'true')
        .toList();
    _soundLevel = widget.initialAlarm.soundLevel;
    _isVibration = widget.initialAlarm.isVibration;
  }

  @override
  void dispose() {
    _alarmNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            TimePickerSpinner(
              locale: const Locale('en', ''),
              time: toDateTimeFromTimeOfDay(_selectedTime),
              is24HourMode: true,
              isShowSeconds: false,
              itemHeight: 60,
              itemWidth: 100,
              alignment: Alignment.center,
              normalTextStyle: const TextStyle(
                fontSize: 48,
              ),
              highlightedTextStyle:
              const TextStyle(fontSize: 48, color: Colors.blue),
              isForce2Digits: true,
              onTimeChange: (time) {
                setState(() {
                  _selectedTime = toTimeOfDayFromDateTime(time);
                });
              },
            ),
            const SizedBox(height: 20),
            Card(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(getDateText(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List<Widget>.generate(7 * 2 - 1, (int index) {
                        if (index % 2 == 1) {
                          return const SizedBox(width: 8); // Spacer
                        }
                        int dayIndex = index ~/ 2;
                        final bool isActive = _daysActive[dayIndex];
                        final bool isWeekend = dayIndex == 5 || dayIndex == 6;
                        final Color borderColor =
                        isActive ? Colors.lightBlue : Colors.transparent;
                        final Color activeTextColor =
                        isActive ? Colors.lightBlue : Colors.black;
                        final Color inactiveTextColor =
                        isWeekend ? Colors.red : Colors.black;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _daysActive[dayIndex] = !_daysActive[dayIndex];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][dayIndex],
                              style: TextStyle(
                                  color: isActive ? activeTextColor : inactiveTextColor),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _alarmNameController,
                      decoration: InputDecoration(
                        labelText: 'Alarm Adı',
                        counterText: '', // This hides the counter
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(width: 2.0), // This makes the underline thicker
                        ),
                      ),
                      maxLength: 60,
                    ),
                  ),
                  Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Text('Ses Seviyesi', style: TextStyle(fontSize: 16)),
                      ),
                      Expanded(
                        child: Slider(
                          value: _soundLevel.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _soundLevel.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _soundLevel = value.round();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Text('Titreşim', style: TextStyle(fontSize: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Switch(
                          value: _isVibration,
                          onChanged: (bool value) {
                            setState(() {
                              _isVibration = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.initialAlarm.id != null) {
                      await DatabaseHelper.instance.delete(widget.initialAlarm.id!);
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Sil'),
                ),
                ElevatedButton(
                  onPressed: () {
                    bool isAlarmSingle = true;
                    for (int i = 0; i < _daysActive.length; i++) {
                      if (_daysActive[i]) {
                        isAlarmSingle = false;
                        break;
                      }
                    }
                    final alarm = AlarmItem(
                      id: widget.initialAlarm.id,
                      name: _alarmNameController.text,
                      time: to24hFormat(_selectedTime),
                      daysActive: _daysActive.isEmpty ? "" : _daysActive.join(','),
                      isActive: true,
                      isSingleAlarm: isAlarmSingle,
                      soundLevel: _soundLevel,
                      isVibration: _isVibration,
                    );
                    saveOrUpdateTheAlarm(alarm);
                    showClosestAlarmToastMessage(alarm);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void saveOrUpdateTheAlarm(AlarmItem alarm) async {
    if (widget.isNew) {
      await DatabaseHelper.instance.create(alarm);
    } else {
      await DatabaseHelper.instance.update(alarm);
    }
  }

  String getDateText() {
    String textToReturn = "";

    // Check if all elements in _daysActive are false
    if (_daysActive.every((day) => day == false)) {
      final now = DateTime.now();
      final alarmTimeToday = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
      if (now.isAfter(alarmTimeToday)) {
        // The alarm is set for tomorrow
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        textToReturn = "Yarın - " + getDayMonth(tomorrow);
      } else {
        // The alarm is set for today
        textToReturn = "Bugün - " + getDayMonth(now);
      }
    } else {
      for (int i = 0; i < _daysActive.length; i++) {
        if (_daysActive[i]) {
          textToReturn += getShortDayName(i + 1) + ", ";
        }
      }
      // Remove the trailing comma
      if (textToReturn.endsWith(",")) {
        textToReturn = textToReturn.substring(0, textToReturn.length - 1);
      }
      textToReturn = "Her $textToReturn";
    }

    return textToReturn;
  }

}
