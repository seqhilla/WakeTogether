import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _requests = [];


  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final querySnapshot = await _firestore
        .collection('requests')
        .where('to', isEqualTo: FirebaseAuth.instance.currentUser!.email!)
        .get();

    for (var doc in querySnapshot.docs) {
      // Only add the request to the list if it has not been accepted
      if (!doc['isAccepted']) {
        setState(() {
          _requests.add(
            {
              'from': doc['from'],
              'alarmId': doc['forAlarm'],
              'isAccepted': doc['isAccepted'],
              'docId': doc.id,
            },
          );
        });
      }
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    // Get the email of the accepting user
    String acceptingUserEmail = FirebaseAuth.instance.currentUser!.email!;

    // Add the alarm to the accepting user's alarms
    await _firestore.collection('alarms').add({
      'alarmId': request['alarmId'],
      'email': acceptingUserEmail,
    });

    // Update the 'isAccepted' field of the request
    await _firestore.collection('requests').doc(request['docId']).update({
      'isAccepted': true,
    });

    // Find the alarm in the 'alarms' collection
    DocumentSnapshot alarmSnapshot = await _firestore
        .collection('alarms')
        .doc('${request['from']}_${request['alarmId']}')
        .get();

    // Get the current list of users for the alarm
    List<String> alarmUsers = List<String>.from(alarmSnapshot['AlarmUsers']);

    // Add the accepting user's email to the list
    alarmUsers.add(acceptingUserEmail);

    // Get the current list of alarm states
    List<int> alarmStates = List<int>.from(alarmSnapshot['AlarmStates']);

    // Add 99 to the alarm states
    alarmStates.add(99);

    // Update the 'AlarmUsers' and 'AlarmStates' field of the alarm
    await _firestore
        .collection('alarms')
        .doc('${request['from']}_${request['alarmId']}')
        .update({'AlarmUsers': alarmUsers, 'AlarmStates': alarmStates});

    // Find the index of the request in the list
    int requestIndex = _requests.indexOf(request);

    // Remove the request from the local list of requests
    setState(() {
      _requests.removeAt(requestIndex);
    });
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    // Delete the request from Firestore
    await _firestore.collection('requests').doc(request['docId']).delete();

    // Find the index of the request in the list
    int requestIndex = _requests.indexOf(request);

    // Remove the request from the local list of requests
    setState(() {
      _requests.removeAt(requestIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelen İstekler'),
      ),
      body: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_requests[index]['from']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _acceptRequest(_requests[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _rejectRequest(_requests[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}