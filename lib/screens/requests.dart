import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _requests = [];


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

    // Update the 'AlarmUsers' field of the alarm
    await _firestore
        .collection('alarms')
        .doc('${request['from']}_${request['alarmId']}')
        .update({'AlarmUsers': alarmUsers});

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
        title: Text('Gelen İstekler'),
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
                  icon: Icon(Icons.check),
                  onPressed: () => _acceptRequest(_requests[index]),
                ),
                IconButton(
                  icon: Icon(Icons.close),
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