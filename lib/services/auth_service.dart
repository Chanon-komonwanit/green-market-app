import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart'; // For BuildContext if showing SnackBars

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmailPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific errors (e.g., user-not-found, wrong-password)
      String errorMessage = "เกิดข้อผิดพลาดในการเข้าสู่ระบบ";
      if (e.code == 'user-not-found') {
        errorMessage = 'ไม่พบบัญชีผู้ใช้นี้';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'ข้อมูลการเข้าสู่ระบบไม่ถูกต้อง';
      }
      // Show error to user (e.g., using SnackBar)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      print('Error signing in: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("เกิดข้อผิดพลาดที่ไม่คาดคิด"),
              backgroundColor: Colors.red),
        );
      }
      print('Unexpected error signing in: $e');
      return null;
    }
  }

  // Sign up with Email and Password
  Future<UserCredential?> signUpWithEmailPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a user document in Firestore upon successful registration
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': false, // Default role
          'isSeller': false, // Default role
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "เกิดข้อผิดพลาดในการสมัครสมาชิก";
      if (e.code == 'weak-password') {
        errorMessage = 'รหัสผ่านคาดเดาง่ายเกินไป (ต้องมีอย่างน้อย 6 ตัวอักษร)';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      print('Error signing up: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("เกิดข้อผิดพลาดที่ไม่คาดคิด"),
              backgroundColor: Colors.red),
        );
      }
      print('Unexpected error signing up: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    print('User signed out');
  }

  // TODO: Add other methods like Google Sign-In, Apple Sign-In, Password Reset, etc.
}
