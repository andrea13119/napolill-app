import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Sign in error: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Create account error: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      developer.log('Google sign in error: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Re-authenticate user with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In wurde abgebrochen');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_auth.currentUser != null) {
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      }
    } catch (e) {
      developer.log('Google re-authentication error: $e',
          name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Re-authenticate user with email and password
  Future<void> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth.currentUser != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await _auth.currentUser!.reauthenticateWithCredential(credential);
      }
    } catch (e) {
      developer.log('Email re-authentication error: $e',
          name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Check if user is signed in with Google
  bool isSignedInWithGoogle() {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if user has Google provider
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  /// Delete user account with automatic re-authentication if needed
  Future<void> deleteAccount({
    String? email,
    String? password,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Kein angemeldeter User gefunden');
    }

    try {
      // Try to delete account
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Re-authentication required
        if (isSignedInWithGoogle()) {
          // Re-authenticate with Google
          await reauthenticateWithGoogle();
        } else if (email != null && password != null) {
          // Re-authenticate with email and password
          await reauthenticateWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          // Re-authentication needed but credentials not provided
          rethrow;
        }

        // Try to delete again after re-authentication
        await _auth.currentUser!.delete();
      } else {
        rethrow;
      }
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      developer.log('Reset password error: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(displayName);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }
}
