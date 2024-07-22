import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SearchUserScreen extends StatefulWidget {
  final int? alarmId;

  SearchUserScreen({super.key, required this.alarmId});

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _printMatchingRequests(FirebaseAuth.instance.currentUser!.email!);
  }

  @override
  Widget build(BuildContext context) {

    final res = GeneralUtils.resources(context).add_user;

    return Scaffold(
      appBar: AppBar(
        title: Text(res.search_user),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: res.enter_email,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchUser(_searchController.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _searchResults[index]['email'],
                    style: TextStyle(
                      color: _searchResults[index]['accepted'] ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.red,
                    onPressed: () {
                      _cancelRequest(index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchUser(String email) async {
    _printMatchingRequests(FirebaseAuth.instance.currentUser!.email!);
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String loggedInUserEmail = FirebaseAuth.instance.currentUser!.email!;
      String docId = loggedInUserEmail + '_' + widget.alarmId.toString();
      final existingRequest = await _firestore.collection('requests').doc(docId).get();
      if (loggedInUserEmail == email) {
        Fluttertoast.showToast(msg: res.self_request);
        return;
      } else if (existingRequest.exists) {
        Fluttertoast.showToast(msg: res.existing_request);
        return;
      } else {
        Fluttertoast.showToast(msg: res.request_sent);
        await _sendRequest(loggedInUserEmail, email, docId);
        setState(() {
          _searchResults.add({
            'email': querySnapshot.docs.first['email'],
            'accepted': false,
          });
        });
      }
    } else {
      Fluttertoast.showToast(msg: res.user_not_found);
    }
    _searchController.clear();
  }

  void _cancelRequest(int index) {
    // Get the request to be cancelled
    Map<String, dynamic> request = _searchResults[index];

    // Construct the document ID
    String docId = FirebaseAuth.instance.currentUser!.email! + '_' + widget.alarmId.toString();

    // Delete the request from Firestore
    _firestore.collection('requests').doc(docId).delete();
    // Listeden isteği kaldır
    setState(() {
      _searchResults.removeAt(index);
    });
  }

  Future<void> _sendRequest(String senderEmail, String receiverEmail, String docId) async {
    await _firestore.collection('requests').doc(docId).set({
      'from': senderEmail,
      'to': receiverEmail,
      'forAlarm': widget.alarmId,
      'isAccepted': false,
    });
  }

  Future<void> _printMatchingRequests(String senderEmail) async {
    String docId = senderEmail + '_' + widget.alarmId.toString();

    final querySnapshot = await _firestore
        .collection('requests')
        .where(FieldPath.documentId, isEqualTo: docId)
        .get();
    _searchResults.clear();
    for (var doc in querySnapshot.docs) {
      setState(() {
        _searchResults.add(
          {
            'email': doc['to'],
            'accepted': doc['isAccepted'],
          },
        );
      });
    }
  }
}