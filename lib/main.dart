import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:waketogether/screens/home_page.dart';
import 'package:waketogether/screens/pre_login_screen.dart';
import 'package:waketogether/utils/DatabaseHelper.dart';

import 'data/AlarmItem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

void _loadAlarms() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the email of the current user
  String userEmail = FirebaseAuth.instance.currentUser!.email!;

  // Clear all alarms from the local database
  await DatabaseHelper.instance.deleteAll();

  // Query the 'alarms' collection in Firestore
  final alarmsSnapshot = await _firestore
      .collection('alarms')
      .where('AlarmUsers', arrayContains: userEmail)
      .get();
  // For each document in the query result
  for (var doc in alarmsSnapshot.docs) {
    // Create an AlarmItem object with the data from the document
    AlarmItem alarm = AlarmItem(
      id:doc['id'],
      name: doc['name'],
      time: doc['time'],
      daysActive: doc['daysActive'],
      isActive: doc['isActive'],
      isSingleAlarm: doc['isSingleAlarm'],
      soundLevel: doc['soundLevel'],
      isVibration: doc['isVibration'],
    );

    // Add the alarm to the local database
    await DatabaseHelper.instance.create(alarm);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _defaultHome = SignInPage();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        setState(() {
          _defaultHome = SignInPage();
        });
      } else {
        setState(() {
          _defaultHome = const MyHomePage(title: 'WakeTogether');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeTogether',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _defaultHome,
    );
  }
}
