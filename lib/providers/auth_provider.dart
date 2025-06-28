// lib/providers/auth_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  User? _user;
  bool _isInitializing = true;
  StreamSubscription<User?>? _authStateSubscription;

  AuthProvider(this._firebaseService) {
    _listenToAuthChanges();
  }

  User? get user => _user;
  bool get isInitializing => _isInitializing;

  void _listenToAuthChanges() {
    _authStateSubscription =
        _firebaseService.authStateChanges.listen((newUser) {
      _user = newUser;
      if (_isInitializing) {
        _isInitializing = false;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _firebaseService.logger.e('Sign in failed', error: e);
      rethrow;
    }
  }

  Future<void> registerWithEmailPassword(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Update display name in Firebase Auth
        await firebaseUser.updateDisplayName(displayName);

        // Create user document in Firestore
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: email,
          displayName: displayName,
          createdAt: Timestamp.fromDate(DateTime.now()),
        );
        await _firebaseService.createOrUpdateAppUser(appUser, merge: false);
      }
    } catch (e) {
      _firebaseService.logger.e('Registration failed', error: e);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      final firebaseUser = userCredential?.user;

      if (firebaseUser != null) {
        // Check if user exists in Firestore
        final appUser = await _firebaseService.getAppUser(firebaseUser.uid);

        if (appUser == null) {
          // If new user, create document in Firestore
          final newUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            createdAt: Timestamp.fromDate(DateTime.now()),
          );
          await _firebaseService.createOrUpdateAppUser(newUser, merge: false);
        }
      }
    } catch (e) {
      _firebaseService.logger.e('Google Sign-In failed', error: e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      _firebaseService.logger.e('Password reset failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      _firebaseService.logger.e('Sign out failed', error: e);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> signIn(String email, String password) =>
      signInWithEmailPassword(email, password);
}
