import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Sign in with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');
      
      // Check if user is already signed in
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      if (account == null) {
        // Trigger the authentication flow
        account = await _googleSignIn.signIn();
      }

      if (account != null) {
        print('🔵 Google Sign In successful: ${account.email}');
        print('🔵 User name: ${account.displayName}');
        print('🔵 User photo: ${account.photoUrl}');
        
        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await account.authentication;
        print('🔵 Access token: ${googleAuth.accessToken?.substring(0, 20)}...');
        print('🔵 ID token: ${googleAuth.idToken?.substring(0, 20)}...');
        
        return account;
      } else {
        print('🔵 Google Sign In cancelled by user');
        return null;
      }
    } on PlatformException catch (e) {
      print('🔴 Google Sign In Platform Exception: ${e.code} - ${e.message}');
      throw GoogleAuthException('Google Sign In failed: ${e.message}');
    } catch (e) {
      print('🔴 Google Sign In Error: $e');
      throw GoogleAuthException('Google Sign In failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('🔵 Google Sign Out successful');
    } catch (e) {
      print('🔴 Google Sign Out Error: $e');
      throw GoogleAuthException('Google Sign Out failed: $e');
    }
  }

  /// Get current Google user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  /// Check if user is signed in with Google
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  /// Disconnect Google account (more permanent than sign out)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      print('🔵 Google account disconnected');
    } catch (e) {
      print('🔴 Google disconnect Error: $e');
      throw GoogleAuthException('Google disconnect failed: $e');
    }
  }
}

class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);

  @override
  String toString() => 'GoogleAuthException: $message';
}