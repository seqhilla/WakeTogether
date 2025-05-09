import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waketogether/data/AlarmItem.dart';
import 'package:waketogether/utils/TimeUtils.dart';

import '../utils/GeneralUtils.dart';
import '../widgets/time_picker.dart';
import 'add_user.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _alarmNameController =
        TextEditingController(text: widget.initialAlarm.name);
    _selectedTime = TimeUtils.toTimeOfDay(widget.initialAlarm.time);
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
            const SizedBox(height: 40),
            ChangeNotifierProvider(
              create: (_) => TimeProvider(_selectedTime),
              child: CustomTimePicker(onTimeChanged: (TimeOfDay value) {
                setState(() {
                  _selectedTime = value;
                });
              },),
            ),
            const SizedBox(height: 20),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  elevation: 5.0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0))),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(getDateText(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children:
                              List<Widget>.generate(7 * 2 - 1, (int index) {
                            if (index % 2 == 1) {
                              return const SizedBox(width: 8); // Spacer
                            }
                            int dayIndex = index ~/ 2;
                            final bool isActive = _daysActive[dayIndex];
                            final bool isWeekend =
                                dayIndex == 5 || dayIndex == 6;
                            final Color borderColor = isActive
                                ? Colors.lightBlue
                                : Colors.transparent;
                            final Color activeTextColor =
                                isActive ? Colors.lightBlue : Colors.black;
                            final Color inactiveTextColor =
                                isWeekend ? Colors.red : Colors.black;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _daysActive[dayIndex] =
                                      !_daysActive[dayIndex];
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
                                      color: isActive
                                          ? activeTextColor
                                          : inactiveTextColor),
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
                          decoration: const InputDecoration(
                            labelText: 'Alarm Adı',
                            counterText: '', // This hides the counter
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  width:
                                      2.0), // This makes the underline thicker
                            ),
                          ),
                          maxLength: 60,
                        ),
                      ),
                      Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text('Ses Seviyesi',
                                style: TextStyle(fontSize: 16)),
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
                            child: Text('Titreşim',
                                style: TextStyle(fontSize: 16)),
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
                )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                if (!widget.isNew)
                  Builder(
                    builder: (context) {
                      String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
                      bool isOwner = widget.initialAlarm.alarmUsers[0] == currentUserEmail;

                      return ElevatedButton(
                        onPressed: isOwner ? _deleteAlarmAndRequests : _leaveAlarm,
                        child: Text(isOwner ? 'Sil' : 'Ayrıl'),
                      );
                    },
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
                      time: TimeUtils.to24hFormat(_selectedTime),
                      daysActive: _daysActive.isEmpty ? "" : _daysActive.join(','),
                      isActive: true,
                      isSingleAlarm: isAlarmSingle,
                      soundLevel: _soundLevel,
                      isVibration: _isVibration,
                      alarmUsers: widget.initialAlarm.alarmUsers,
                      alarmStates: widget.initialAlarm.alarmStates
                    );
                    GeneralUtils.showClosestAlarmToastMessage(alarm);
                    String loggedInUserEmail = FirebaseAuth.instance.currentUser!.email!;
                    _saveOrUpdateAlarmToFirestore(alarm, loggedInUserEmail);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.isNew)
              const Text('Alarmı oluşturduktan sonra kullanıcı ekleyebilirsiniz'),
            if (!widget.isNew)
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchUserScreen(alarmId: widget.initialAlarm.id)),
                  ),
                  child: const Text('Kullanıcıları Yönet'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String getDateText() {
    String textToReturn = "";

    if (_daysActive.every((day) => day == false)) {
      final now = DateTime.now();
      final alarmTimeToday = DateTime(now.year, now.month, now.day,
          _selectedTime.hour, _selectedTime.minute);
      if (now.isAfter(alarmTimeToday)) {
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        textToReturn = "Yarın - ${TimeUtils.getDayMonth(tomorrow)}";
      } else {
        textToReturn = "Bugün - ${TimeUtils.getDayMonth(now)}";
      }
    } else {
      for (int i = 0; i < _daysActive.length; i++) {
        if (_daysActive[i]) {
          textToReturn += "${TimeUtils.getShortDayName(i + 1)}, ";
        }
      }
      if (textToReturn.endsWith(",")) {
        textToReturn = textToReturn.substring(0, textToReturn.length - 1);
      }
      textToReturn = "Her $textToReturn";
    }

    return textToReturn;
  }

  Future<void> _saveOrUpdateAlarmToFirestore(AlarmItem alarm, String userEmail) async {
    int alarmId;
    if (alarm.id == null) {
      int lastAlarmId = await _getLastAlarmId(userEmail);
      alarmId = lastAlarmId + 1;
    } else {
      alarmId = alarm.id!;
    }

    List<String> alarmUsers = [userEmail];
    List<int> alarmStates = [99];

    if (!widget.isNew) {
      final docRef = _firestore.collection('alarms').doc("${alarm.alarmUsers[0]}_${alarm.id}");
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        alarmUsers = List<String>.from(docSnap.data()?['AlarmUsers'] ?? []);
        alarmStates = List<int>.from(docSnap.data()?['AlarmStates'] ?? []);
      }
    }

    final alarmData = {
      'id': alarmId,
      'name': alarm.name,
      'time': alarm.time,
      'daysActive': alarm.daysActive,
      'isActive': alarm.isActive,
      'isSingleAlarm': alarm.isSingleAlarm,
      'soundLevel': alarm.soundLevel,
      'isVibration': alarm.isVibration,
      'AlarmUsers': alarmUsers,
      'AlarmStates': alarmStates,
    };

    await _firestore.collection('alarms').doc("${alarmUsers[0]}_$alarmId").set(alarmData);
    Navigator.pop(context, true);
  }

  Future<int> _getLastAlarmId(String userEmail) async {
    final alarmsSnapshot = await _firestore
        .collection('alarms')
        .where('AlarmUsers', arrayContains: userEmail)
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    if (alarmsSnapshot.docs.isEmpty) {
      return 0; // Return 0 if there are no alarms
    } else {
      return alarmsSnapshot.docs.first.data()['id']; // Return the ID of the last alarm
    }
  }

  Future<void> _deleteAlarmAndRequests() async {
    if (widget.initialAlarm.id != null) {
      try {
        final batch = _firestore.batch();
        String userEmail = FirebaseAuth.instance.currentUser!.email!;

        // Alarmı sil
        final alarmRef = _firestore.collection('alarms')
            .doc("${userEmail}_${widget.initialAlarm.id}");
        batch.delete(alarmRef);

        final requestsSnapshot = await _firestore.collection('requests')
            .where('from', isEqualTo: userEmail)
            .where('forAlarm', isEqualTo: widget.initialAlarm.id)
            .get();

        for (var doc in requestsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm silinirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveAlarm() async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    try {
      // Alarmın güncel verilerini al
      DocumentSnapshot alarmDoc = await _firestore
          .collection('alarms')
          .doc("${widget.initialAlarm.alarmUsers[0]}_${widget.initialAlarm.id}")
          .get();

      if (alarmDoc.exists) {
        Map<String, dynamic> data = alarmDoc.data() as Map<String, dynamic>;
        List<String> alarmUsers = List<String>.from(data['AlarmUsers']);
        List<int> alarmStates = List<int>.from(data['AlarmStates']);

        // Kullanıcının indexini bul
        int userIndex = alarmUsers.indexOf(currentUserEmail);
        if (userIndex != -1) {
          // Kullanıcıyı ve durumunu listelerden çıkar
          alarmUsers.removeAt(userIndex);
          alarmStates.removeAt(userIndex);

          // Firestore'u güncelle
          await _firestore
              .collection('alarms')
              .doc("${widget.initialAlarm.alarmUsers[0]}_${widget.initialAlarm.id}")
              .update({
            'AlarmUsers': alarmUsers,
            'AlarmStates': alarmStates,
          });

          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
