import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:waketogether/utils/GeneralUtils.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createUserDocument(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user != null) {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email, //TODO şuanlık email kullanılıyor nickname vb bir şey bul
          // Add other user properties
        });
      }
    }
  }

  Future<UserCredential?> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create a document for the user in Firestore
      await _createUserDocument(userCredential);

      return userCredential;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    //final res = GeneralUtils.resources(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("res.sign_in"),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text("res.sign_in_google"), //TODO: Furkan burayı yap
          onPressed: () {
            _handleSignIn()
                .then((UserCredential? user) => print(user))
                .catchError((e) => print(e));
          },
        ),
      ),
    );
  }
}
