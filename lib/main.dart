import 'package:flutter/material.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/screens/edit_alarm_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
                    alarmIndex: -1, // Indicates a new alarm
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  if (result['isNew']) {
                    // Add a new alarm
                    alarms.add(AlarmItem(
                      alarmName: result['alarmName'],
                      alarmTime: formatTimeOfDay(result['alarmTime']), // Convert TimeOfDay to String
                      daysActive: result['daysActive'],
                      isActive: true, // Assuming new alarms are active by default
                    ));
                  } else {
                    // Update an existing alarm
                    int index = result['index'];
                    alarms[index].alarmName = result['alarmName'];
                    alarms[index].alarmTime = formatTimeOfDay(result['alarmTime']); // Convert TimeOfDay to String
                    alarms[index].daysActive = result['daysActive'];
                    // isActive remains unchanged or can be updated based on your logic
                  }
                });
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Adjust the padding as needed
            child: alarmListItem(
              alarmName: alarm.alarmName,
              alarmTime: alarm.alarmTime,
              daysActive: alarm.daysActive,
              isActive: alarm.isActive,
              onToggle: (newValue) => _toggleActive(index, newValue),
              context: context,
              index: index,
            ),
          );
        },
      ),
    );
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Widget alarmListItem({
    required String alarmName,
    required String alarmTime,
    required List<bool> daysActive,
    required bool isActive,
    required Function(bool) onToggle,
    required BuildContext context,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAlarmScreen(
              initialAlarmName: alarms[index].alarmName,
              initialAlarmTime: TimeOfDay.now(), // Convert `alarmTime` string to TimeOfDay
              initialDaysActive: alarms[index].daysActive,
              alarmIndex: index, // Index of the existing alarm
            ),
          ),
        );
      },
      child: Container(
        height: 120, // Fixed height for the card
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items in the row
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start, // Aligns horizontally to the start
                    children: [
                      if (alarmName.isNotEmpty)  AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: Text(alarmName, style: const TextStyle(fontSize: 16)),
                      ),
                      AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: Text(alarmTime, style: const TextStyle(fontSize: 42)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8), // Space before the days
                Row(
                  children: List.generate(7, (dayIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // This centers the children vertically
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: daysActive[dayIndex] ? (isActive ? Colors.deepPurple : Colors.grey) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][dayIndex], style: TextStyle(fontSize: 10, color: isActive ? Colors.black : Colors.grey)),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(width: 16), // Added space between the days and the switch
                Switch(
                  value: isActive,
                  onChanged: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}