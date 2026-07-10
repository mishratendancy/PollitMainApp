import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Fetch user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }

  /// Sign up with email and password
  Future<firebase_auth.UserCredential> emailSignUp(
    String email,
    String password, {
    String? fullName,
    String? username,
  }) async {
    final trimmedEmail = email.trim();
    final safeUsername = username?.trim().toLowerCase();
    
    final credential = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    final user = credential.user!;
    
    if (fullName != null && fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
    }

    // Send verification email
    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Failed to send verification email: $e');
    }

    // Create user profile in Firestore to match Poll.io structure
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': fullName?.trim(),
      'photoURL': null,
      'email': user.email ?? trimmedEmail,
      'username': safeUsername,
      'profileSetupCompleted': false,
      'inkmarks': 0,
      'pollsCreated': 0,
      'communitiesCreated': 0,
      'followingCount': 0,
      'voteCount': 0,
      'createdAt': now,
    }, SetOptions(merge: true));

    return credential;
  }

  /// Sign in with email and password
  Future<firebase_auth.UserCredential> emailSignIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Google
  Future<firebase_auth.UserCredential?> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // The user canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      // If it's a new user, create their Firestore profile
      if (user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'email': user.email,
          'username': user.email?.split('@').first ?? 'user_${now.toString().substring(5)}',
          'profileSetupCompleted': false,
          'inkmarks': 0,
          'pollsCreated': 0,
          'communitiesCreated': 0,
          'followingCount': 0,
          'voteCount': 0,
          'createdAt': now,
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    return await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Log out
  Future<void> logout() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  /// Map Firebase Auth error codes to user-friendly messages matching Poll.io
  String getAuthErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use 12–20 characters with uppercase, lowercase, numbers, and symbols.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again in 15–30 minutes.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is disabled in Firebase.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
