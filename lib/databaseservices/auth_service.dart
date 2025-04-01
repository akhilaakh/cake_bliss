import 'dart:developer';

import 'package:cakebliss_admin/Screen/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<User?> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the login
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
      return userCredential.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> sendPassWordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      log("google signin failed :$e ");
      print(e.toString());
    }
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      ExceptionHandler(e.code);
    } catch (e) {
      log('something ');
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
      // } on FirebaseAuthException catch (e) {
      //   ExceptionHandler(e.code);
    } catch (e) {
      log('$e');
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("something went ");
    }
  }
}

ExceptionHandler(String code) {
  switch (code) {
    case "invalid-credential":
      log("your login creadnetials are invalid");
    case "week password":
      log("your password must be at 8 charecters");
    case "email already in use":
      log("user already exists ");
    default:
      log("something  wrong");
  }
}
