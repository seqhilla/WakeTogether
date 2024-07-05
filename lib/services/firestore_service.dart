import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/AlarmItem.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();



}