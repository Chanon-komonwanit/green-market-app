// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Firebase Auth User
import 'package:green_market/services/firebase_service.dart'; // Your FirebaseService

class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  fb_auth.User? _firebaseUser; // The authenticated user from Firebase Auth
  Map<String, dynamic>?
      _userData; // User data from Firestore (e.g., roles, display name)

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _listenToAuthChanges();
  }

  fb_auth.User? get currentUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;

  bool get isLoggedIn => _firebaseUser != null;

  bool get isAdmin {
    if (_userData != null && _userData!['isAdmin'] == true) {
      return true;
    }
    return false;
  }

  // Listen to Firebase Auth state changes
  void _listenToAuthChanges() {
    fb_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((fb_auth.User? user) async {
      print(
          "UserProvider (authStateChanges): Auth state changed. User: ${user?.email}, UID: ${user?.uid}");
      _setLoading(true);
      if (user != null) {
        _firebaseUser = user;
        await _loadUserData(user.uid); // Load Firestore data
      } else {
        _firebaseUser = null;
        _userData = null; // Clear user data on logout
        print("UserProvider (authStateChanges): User logged out.");
      }
      _setLoading(false);
      notifyListeners();
    });
  }

  // Load user-specific data from Firestore
  Future<void> _loadUserData(String uid) async {
    print(
        "UserProvider (_loadUserData): Attempting to load user data for UID: $uid");
    try {
      _userData = await _firebaseService.getUserData(uid);
      if (_userData != null) {
        print(
            "UserProvider (_loadUserData): Successfully loaded user data: $_userData");
        print(
            "UserProvider (_loadUserData): isAdmin flag from Firestore: ${_userData!['isAdmin']}");
      } else {
        print(
            "UserProvider (_loadUserData): No user data found in Firestore for UID: $uid. This might be expected for a new user before Firestore doc is created, or an issue.");
      }
    } catch (e, s) {
      print(
          "UserProvider (_loadUserData): Error loading user data for UID $uid: $e");
      print("UserProvider (_loadUserData): Stacktrace: $s");
      _userData = null; // Ensure userData is null on error
    }
    // notifyListeners() will be called by the calling function (_listenToAuthChanges or signIn)
  }

  // Sign in method
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    notifyListeners();
    try {
      print("UserProvider (signIn): Attempting to sign in user: $email");
      final fb_auth.User? user = await _firebaseService.signIn(email, password);
      if (user != null) {
        _firebaseUser = user;
        print(
            "UserProvider (signIn): Firebase sign-in successful for ${user.email}, UID: ${user.uid}");
        // _loadUserData will be triggered by authStateChanges listener,
        // but you can also call it here explicitly if needed for immediate data after signIn.
        // However, relying on authStateChanges is often cleaner.
        // If you call it here, ensure authStateChanges handles potential race conditions or duplicate loads.
        // For now, let's assume authStateChanges is sufficient.
        // await _loadUserData(user.uid); // Potentially redundant if authStateChanges is quick
        _setLoading(false);
        notifyListeners(); // Notify for UI update after sign-in attempt
        return true;
      } else {
        print(
            "UserProvider (signIn): Firebase sign-in failed for $email. FirebaseService returned null.");
        _firebaseUser = null;
        _userData = null;
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      print("UserProvider (signIn): Error during sign in for $email: $e");
      print("UserProvider (signIn): Stacktrace: $s");
      _firebaseUser = null;
      _userData = null;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign up method
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    notifyListeners();
    try {
      print("UserProvider (signUp): Attempting to sign up user: $email");
      final fb_auth.User? user = await _firebaseService.signUp(email, password);
      if (user != null) {
        _firebaseUser = user;
        print(
            "UserProvider (signUp): Firebase sign-up successful for ${user.email}, UID: ${user.uid}");
        // _loadUserData will be triggered by authStateChanges.
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        print("UserProvider (signUp): Firebase sign-up failed for $email.");
        _firebaseUser = null;
        _userData = null;
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      print("UserProvider (signUp): Error during sign up for $email: $e");
      print("UserProvider (signUp): Stacktrace: $s");
      _firebaseUser = null;
      _userData = null;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    print("UserProvider (signOut): Signing out user: ${_firebaseUser?.email}");
    await _firebaseService.signOut();
    // Auth state listener will handle clearing _firebaseUser and _userData
    // No need to call notifyListeners() here, as authStateChanges will do it.
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      // Optionally, notify listeners immediately if the loading state is critical for UI updates.
      // notifyListeners();
    }
  }

  Future<void> refreshUserData() async {}

  // Add other methods like updateUserProfile, etc.
}
