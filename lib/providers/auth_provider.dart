import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  firebase_auth.User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = false;

  AuthProvider() {
    _init();
  }

  firebase_auth.User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;

  Future<void> _init() async {
    // Step 1: Check synchronously if Firebase already knows the user.
    // After Firebase.initializeApp() completes (which happens before runApp),
    // currentUser is immediately available if a session was persisted.
    final existingUser = firebase_auth.FirebaseAuth.instance.currentUser;
    debugPrint('AuthProvider._init() → currentUser = ${existingUser?.uid ?? "NULL"}');

    if (existingUser != null) {
      // User is already authenticated from a previous session.
      // Set the user immediately so the UI never flashes the login screen.
      _user = existingUser;
      _isLoading = false;
      _isProfileLoading = true;
      notifyListeners();

      // Fetch Firestore profile
      _userProfile = await _authService.getUserProfile(existingUser.uid);
      _isProfileLoading = false;
      debugPrint('AuthProvider._init() → profile loaded, profileSetupCompleted = ${_userProfile?['profileSetupCompleted']}');
      notifyListeners();
    }

    // Step 2: Subscribe to ongoing auth changes (login, logout, token refresh).
    // This handles all future state changes AFTER the initial load above.
    _authSubscription = _authService.authStateChanges.listen(
      (firebase_auth.User? user) async {
        debugPrint('AuthProvider stream event → user = ${user?.uid ?? "NULL"}');

        // If the stream emits the same user we already loaded above, skip.
        if (_user?.uid == user?.uid && !_isLoading) {
          return;
        }

        _user = user;
        _isLoading = false;

        if (user != null) {
          _isProfileLoading = true;
          notifyListeners();

          _userProfile = await _authService.getUserProfile(user.uid);
          _isProfileLoading = false;
        } else {
          _userProfile = null;
          _isProfileLoading = false;
        }

        notifyListeners();
      },
    );

    // If there was no existing user, the stream will fire shortly with null.
    // Mark loading as done either way after a short safety timeout.
    if (existingUser == null) {
      // Give the stream a moment to emit, then force loading = false.
      // On most devices the stream fires within ~100ms.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isLoading) {
          debugPrint('AuthProvider → safety timeout, forcing isLoading = false');
          _isLoading = false;
          notifyListeners();
        }
      });
    }
  }

  Future<void> reloadProfile() async {
    if (_user != null) {
      _userProfile = await _authService.getUserProfile(_user!.uid);
      notifyListeners();
    }
  }

  Future<void> completeProfileSetup(String displayName, String photoURL) async {
    if (_user != null) {
      await _authService.updateUserProfileSetup(_user!.uid, displayName, photoURL);
      await reloadProfile();
    }
  }

  Future<void> signIn(String email, String password) async {
    await _authService.emailSignIn(email, password);
  }

  Future<void> signInWithGoogle() async {
    await _authService.googleSignIn();
    await reloadProfile();
  }

  Future<void> signInWithGithub() async {
    await _authService.githubSignIn();
    await reloadProfile();
  }

  Future<void> signInWithTwitter() async {
    await _authService.twitterSignIn();
    await reloadProfile();
  }

  Future<void> signInWithFacebook() async {
    await _authService.facebookSignIn();
    await reloadProfile();
  }

  Future<void> signUp(String email, String password, {String? fullName, String? username}) async {
    await _authService.emailSignUp(
      email,
      password,
      fullName: fullName,
      username: username,
    );
    await reloadProfile();
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> logout() async {
    await _authService.logout();
    // Explicitly clear local state so UI reacts immediately
    _user = null;
    _userProfile = null;
    notifyListeners();
  }

  String getErrorMessage(dynamic error) {
    return _authService.getAuthErrorMessage(error);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
