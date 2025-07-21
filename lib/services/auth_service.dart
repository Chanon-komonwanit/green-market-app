import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart'; // For BuildContext if showing SnackBars
import 'package:google_sign_in/google_sign_in.dart';

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

  // Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Google Sign-In

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        print('Google Sign-In successful: ${user.email}');
        // Check if this is a new user and create profile if needed
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          // Create new user profile
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'profileImageUrl': user.photoURL ?? '',
            'role': 'buyer',
            'isActive': true,
            'isSeller': false,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          });
          print('New Google user profile created');
        } else {
          // Update last login time
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      print('Error with Google Sign-In: $e');
      return null;
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        print('Re-authentication successful');
        return true;
      }
      return false;
    } catch (e) {
      print('Error with re-authentication: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Delete the authentication account
        await user.delete();
        print('User account deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  // Apple Sign-In (placeholder for future implementation)
  Future<User?> signInWithApple() async {
    // TODO: [ภาษาไทย] พัฒนา Apple Sign-In เมื่อพร้อมใช้งาน (ต้องใช้ apple_sign_in package และตั้งค่า iOS)
    throw UnimplementedError('Apple Sign-In not yet implemented');
  }
}
