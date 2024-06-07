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
  }

  @override
  void dispose() {
    _alarmNameController.dispose();
    super.dispose();
  }

  /*
  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  */
  void _pickTime() async {}

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
            // Added space between alarm time and day selection
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List<Widget>.generate(7 * 2 - 1, (int index) {
                  if (index % 2 == 1) {
                    return SizedBox(width: 8); // Spacer
                  }
                  int dayIndex = index ~/ 2;
                  final bool isActive = _daysActive[dayIndex];
                  final bool isWeekend = dayIndex == 5 || dayIndex == 6;
                  final Color borderColor =
                      isActive ? Colors.lightBlue : Colors.transparent;
                  //final Color activeBackgroundColor = isActive ? Colors.lightBlue[100]! : Colors.transparent;
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
                            color:
                                isActive ? activeTextColor : inactiveTextColor),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            // Added space before the TextField
            Padding(
              padding: const EdgeInsets.all(16.0),
              // Adjust the padding value as needed
              child: TextField(
                controller: _alarmNameController,
                decoration: const InputDecoration(
                  labelText: 'Alarm Adı',
                ),
                maxLength: 15, // Limit the input to 15 characters
              ),
            ),
            const SizedBox(height: 20),
            // Added space before the buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    //save the alarm
                    final alarm = AlarmItem(
                      id: widget.initialAlarm.id,
                      name: _alarmNameController.text,
                      time: to24hFormat(_selectedTime),
                      daysActive: _daysActive.join(','),
                      isActive: true,
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
}
