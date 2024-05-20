import 'package:flutter/material.dart';
import 'package:waketogether/utils/TimeUtils.dart';

class EditAlarmScreen extends StatefulWidget {
  final String initialAlarmName;
  final TimeOfDay initialAlarmTime;
  final List<bool> initialDaysActive;
  final int alarmIndex;

  const EditAlarmScreen({
    Key? key,
    required this.initialAlarmName,
    required this.initialAlarmTime,
    required this.initialDaysActive,
    required this.alarmIndex,
  }) : super(key: key);

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
    _alarmNameController = TextEditingController(text: widget.initialAlarmName);
    _selectedTime = widget.initialAlarmTime;
    _daysActive = List.from(widget.initialDaysActive);
  }

  @override
  void dispose() {
    _alarmNameController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text('Alarm Zamanı'),
              trailing: Text(to24hFormat(_selectedTime)),
              onTap: _pickTime,
            ),
            SizedBox(height: 20), // Added space between alarm time and day selection
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
                  final Color borderColor = isActive ? Colors.lightBlue : Colors.transparent;
                  final Color activeBackgroundColor = isActive ? Colors.lightBlue[100]! : Colors.transparent;
                  final Color activeTextColor = isActive ? Colors.lightBlue : Colors.black;
                  final Color inactiveTextColor = isWeekend ? Colors.red : Colors.black;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _daysActive[dayIndex] = !_daysActive[dayIndex];
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeBackgroundColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][dayIndex],
                        style: TextStyle(color: isActive ? activeTextColor : inactiveTextColor),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 20), // Added space before the TextField
            Padding(
              padding: const EdgeInsets.all(16.0), // Adjust the padding value as needed
              child: TextField(
                controller: _alarmNameController,
                decoration: InputDecoration(labelText: 'Alarm Name'),
              ),
            ),
            SizedBox(height: 20), // Added space before the buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () { //TODO: 24 Biçiminde yapma seçeneği ekle
                    Navigator.pop(context, {
                      'alarmName': _alarmNameController.text,
                      'alarmTime': _selectedTime,
                      'daysActive': _daysActive,
                      'isNew': widget.alarmIndex == -1, // Determine if the alarm is new
                      'index': widget.alarmIndex, // Pass the index back
                    });
                  },
                  child: Text('Kaydet'),
                ),
              ],
            ),
            SizedBox(height: 20), // Added space at the bottom for better spacing
          ],
        ),
      ),
    );
  }
}