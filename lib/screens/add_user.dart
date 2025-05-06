import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:waketogether/utils/GeneralUtils.dart';
//TODO: LİSTE YANLIŞ HACI DÜZELT GELEN KİŞİLER DOĞRU DEĞİL BELKİ DE ALARM USERS + REQUESTS BAKMAK LAZIM
class SearchUserScreen extends StatefulWidget {
  final int? alarmId;

  const SearchUserScreen({super.key, required this.alarmId});

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _printMatchingRequests(FirebaseAuth.instance.currentUser!.email!);
    _listenForUpdates();
  }

  @override
  Widget build(BuildContext context) {

    final res = GeneralUtils.resources(context);

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
              onSubmitted: (value) => _searchUser(value),
              decoration: InputDecoration(
                labelText: res.enter_email,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
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
    AppLocalizations res = GeneralUtils.resources(context);
    _printMatchingRequests(FirebaseAuth.instance.currentUser!.email!);
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String loggedInUserEmail = FirebaseAuth.instance.currentUser!.email!;
      String docId = '${loggedInUserEmail}_${widget.alarmId}';
      final existingRequest = await _firestore.collection('requests').doc(docId).get();
      if (loggedInUserEmail == email) {
        Fluttertoast.showToast(msg: res.self_request);
        return;
      } else if (existingRequest.exists) {
          Fluttertoast.showToast(msg: res.existing_request);
        return;
      } else {
        await _sendRequest(loggedInUserEmail, email, docId);
        Fluttertoast.showToast(msg: res.request_sent);
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

  void _cancelRequest(int index) async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    String docId = '${currentUserEmail}_${widget.alarmId}';
    String targetUserEmail = _searchResults[index]['email'];

    // Request'i sil
    await _firestore.collection('requests').doc(docId).delete();

    // Alarm Users'dan kullanıcıyı sil
    final alarmDoc = await _firestore
        .collection('alarms')
        .doc("${currentUserEmail}_${widget.alarmId}")
        .get();

    if (alarmDoc.exists) {
      List<String> alarmUsers = List<String>.from(alarmDoc['AlarmUsers']);
      List<int> alarmStates = List<int>.from(alarmDoc['AlarmStates']);

      int userIndex = alarmUsers.indexOf(targetUserEmail);
      if (userIndex != -1) {
        alarmUsers.removeAt(userIndex);
        alarmStates.removeAt(userIndex);

        await _firestore
            .collection('alarms')
            .doc("${currentUserEmail}_${widget.alarmId}")
            .update({
          'AlarmUsers': alarmUsers,
          'AlarmStates': alarmStates
        });
      }
    }

    // UI'ı güncelle
    setState(() {
      _searchResults.removeAt(index);
      _printMatchingRequests(currentUserEmail);
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
    _searchResults.clear();

    // 1. Alarm Users'ı kontrol et
    final alarmDoc = await _firestore
        .collection('alarms')
        .doc("${senderEmail}_${widget.alarmId}")
        .get();

    if (alarmDoc.exists) {
      List<String> alarmUsers = List<String>.from(alarmDoc['AlarmUsers']);
      // Mevcut kullanıcı dışındaki kullanıcıları al
      alarmUsers.where((email) => email != senderEmail).forEach((email) {
        setState(() {
          _searchResults.add({
            'email': email,
            'accepted': true,
          });
        });
      });
    }

    // 2. Requests'i kontrol et
    String docId = '${senderEmail}_${widget.alarmId}';
    final requestsSnapshot = await _firestore
        .collection('requests')
        .where(FieldPath.documentId, isEqualTo: docId)
        .get();

    for (var doc in requestsSnapshot.docs) {
      String userEmail = doc['to'];
      bool isAccepted = doc['isAccepted'];

      // Eğer kullanıcı zaten _searchResults'ta varsa (alarm users'dan gelmiş) ve
      // request accepted true ise, atla
      bool userExists = _searchResults.any((result) =>
      result['email'] == userEmail && result['accepted']);

      // Kullanıcı listede yoksa veya request accepted false ise ekle
      if (!userExists && !isAccepted) {
        setState(() {
          _searchResults.add({
            'email': userEmail,
            'accepted': false,
          });
        });
      }
    }
  }

  void _listenForUpdates() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    // Requests koleksiyonunu dinle
    firestore
        .collection('requests')
        .where('from', isEqualTo: userEmail)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // Değişiklik bir güncelleme ise
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data() as Map<String, dynamic>;
          // Eğer istek kabul edildiyse
          if (data['isAccepted'] == true) {
            // Listeyi güncelle
            _printMatchingRequests(userEmail);
          }
        }
      }
    });

    // Alarms koleksiyonunu dinle
    firestore
        .collection('alarms')
        .doc("${userEmail}_${widget.alarmId}")
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _printMatchingRequests(userEmail);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

}