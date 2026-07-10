import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  firebase_auth.User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = true;

  AuthProvider() {
    _init();
  }

  firebase_auth.User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;

  void _init() {
    _authService.authStateChanges.listen((firebase_auth.User? user) async {
      _user = user;
      _isLoading = false;
      
      if (user != null) {
        _isProfileLoading = true;
        notifyListeners();
        
        // Fetch extended profile from Firestore
        _userProfile = await _authService.getUserProfile(user.uid);
        _isProfileLoading = false;
      } else {
        _userProfile = null;
        _isProfileLoading = false;
      }
      
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _authService.emailSignIn(email, password);
  }

  Future<void> signInWithGoogle() async {
    await _authService.googleSignIn();
  }

  Future<void> signUp(String email, String password, {String? fullName, String? username}) async {
    await _authService.emailSignUp(
      email,
      password,
      fullName: fullName,
      username: username,
    );
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  String getErrorMessage(dynamic error) {
    return _authService.getAuthErrorMessage(error);
  }
}
