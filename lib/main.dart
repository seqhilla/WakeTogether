import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/screens/edit_alarm_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeTogether',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WakeTogether'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<AlarmItem> alarms = [
    AlarmItem(alarmName: 'Alarm 0', alarmTime: '12:00', daysActive: [true, false, true, false, true, false, true], isActive: true),
    // Add more alarms as needed
  ];

  void _toggleActive(int index, bool newValue) {
    setState(() {
      alarms[index].isActive = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAlarmScreen(
                    initialAlarmName: '',
                    initialAlarmTime: TimeOfDay(hour: 6, minute: 0),
                    initialDaysActive: List<bool>.filled(7, false),
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  // Assuming result is a Map with 'alarmName', 'alarmTime', and 'daysActive'
                  // Update your list based on your app's logic
                  // Add more logic here if you need to store alarm details
                });
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: alarms.length, // Updated to use the length of the alarms list
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return alarmListItem(
            alarmName: alarm.alarmName,
            alarmTime: alarm.alarmTime,
            daysActive: alarm.daysActive,
            isActive: alarm.isActive,
            onToggle: (newValue) => _toggleActive(index, newValue),
            context: context,
          );
        },
      ),
    );
  }

  Widget alarmListItem({
    required String alarmName,
    required String alarmTime,
    required List<bool> daysActive,
    required bool isActive,
    required Function(bool) onToggle,
    required BuildContext context, // Ensure BuildContext is passed as a parameter
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAlarmScreen(
              initialAlarmName: alarmName,
              initialAlarmTime: TimeOfDay.now(), // Adjust based on your needs
              initialDaysActive: daysActive,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alarmName, style: TextStyle(fontSize: 14)),
                Text(alarmTime, style: TextStyle(fontSize: 42)),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(7, (index) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: daysActive[index] ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][index], style: TextStyle(fontSize: 10)), // Day initials
                  ],
                );
              }),
            ),
            const SizedBox(width: 16),
            Switch(
              value: isActive,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }

}
