import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ⚠️ GOOGLE WEB CLIENT ID (From Firebase google-services.json)
/// Project: demoauth-e4cb1 (Project #31988711347)
/// From: https://console.firebase.google.com/project/demoauth-e4cb1
/// Type: OAuth 2.0 Client ID → Web application
const String GOOGLE_WEB_CLIENT_ID = '31988711347-4stuj6ohfel1s5tegnv4mf00ld9vhvcr.apps.googleusercontent.com';

/// 📱 LATEST SHA-1 CERTIFICATES (Generated: Oct 22, 2025 - 3:02 PM)
/// DEBUG SHA-1:   87:3B:CB:51:B6:23:49:A6:5E:49:D7:9D:32:B0:1A:3E:72:63:A4:7B
/// DEBUG SHA-256: 45:10:B0:78:7C:F6:0A:62:88:3B:CB:A4:D7:36:62:CC:30:89:D4:4C:1A:D2:22:23:F8:3D:99:6D:CF:EF:51:78
/// RELEASE SHA-1: 4C:56:DB:EC:12:0D:A1:31:A5:5F:CA:CA:52:33:16:19:45:B8:92:DD

// Google auth result class
class GoogleAuthResult {
  final String? id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;
  final String? serverAuthCode;
  final String? error;

  GoogleAuthResult({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.idToken,
    this.accessToken,
    this.serverAuthCode,
    this.error,
  });

  bool get isSuccess => error == null && id != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photo_url': photoUrl,
    'id_token': idToken,
    'access_token': accessToken,
    'server_auth_code': serverAuthCode,
  };
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Initialize Google Sign In with server client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: GOOGLE_WEB_CLIENT_ID,
  );

  /// Sign in with Google
  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      print('🔵 ========== GOOGLE SIGN IN STARTED ==========');
      print('📱 Web Client ID: $GOOGLE_WEB_CLIENT_ID');
      print('📱 Package Name: com.example.tailer_app');
      print('🔑 Expected SHA-1: 87:3B:CB:51:B6:23:49:A6:5E:49:D7:9D:32:B0:1A:3E:72:63:A4:7B');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('🔧 GoogleSignIn Scopes: ${_googleSignIn.scopes}');
      print('🔧 Server Client ID configured: ${_googleSignIn.serverClientId ?? "NOT SET"}');
      print('==============================================');
      
      print('🔵 Step 1: Calling _googleSignIn.signIn()...');
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      print('🔵 Step 2: signIn() completed');
      
      if (account == null) {
        print('⚠️ User cancelled Google sign in (account is null)');
        return GoogleAuthResult(
          error: 'User cancelled Google sign in',
        );
      }

      print('✅ Step 3: Google account selected successfully!');
      print('   📧 Email: ${account.email}');
      print('   👤 Display Name: ${account.displayName}');
      print('   🆔 Account ID: ${account.id}');
      print('   📸 Photo URL: ${account.photoUrl ?? "No photo"}');
      
      print('🔵 Step 4: Getting authentication tokens...');
      
      // Get authentication details
      final GoogleSignInAuthentication auth = await account.authentication;
      
      print('✅ Step 5: Got authentication tokens successfully!');
      print('   🎫 ID Token: ${auth.idToken != null ? "✅ Present (${auth.idToken!.substring(0, 30)}...)" : "❌ Missing"}');
      print('   🔑 Access Token: ${auth.accessToken != null ? "✅ Present (${auth.accessToken!.substring(0, 30)}...)" : "❌ Missing"}');
      print('   🔐 Server Auth Code: ${auth.serverAuthCode != null ? "✅ Present" : "❌ Missing"}');
      
      print('🎉 ========== GOOGLE SIGN IN SUCCESS ==========');
      
      // Return the user data
      return GoogleAuthResult(
        id: account.id,
        name: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        serverAuthCode: auth.serverAuthCode,
      );
      
    } on PlatformException catch (e) {
      print('🔴 ========== GOOGLE SIGN IN PLATFORM EXCEPTION ==========');
      print('❌ Error Code: ${e.code}');
      print('❌ Error Message: ${e.message}');
      print('❌ Error Details: ${e.details}');
      print('❌ Stack Trace: ${e.stacktrace}');
      print('==========================================================');
      
      // Handle specific error codes
      String errorMessage;
      switch (e.code) {
        case 'sign_in_canceled':
          errorMessage = 'User cancelled Google sign in';
          break;
        case 'network_error':
          errorMessage = 'Network error. Please check your connection';
          break;
        case 'sign_in_failed':
          errorMessage = 'Google sign in failed. Please try again';
          break;
        case '10':
          errorMessage = 'SHA-1 certificate mismatch or OAuth client not configured. Please check Google Console configuration.';
          break;
        default:
          errorMessage = 'Google sign in error: ${e.message ?? e.code}';
      }
      
      return GoogleAuthResult(error: errorMessage);
    } catch (e, stackTrace) {
      print('🔴 ========== GOOGLE SIGN IN GENERAL ERROR ==========');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error: $e');
      print('❌ Stack Trace: $stackTrace');
      print('====================================================');
      return GoogleAuthResult(error: 'Google sign in failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Signed out from Google');
    } catch (e) {
      print('🔴 Error signing out from Google: $e');
    }
  }

  /// Get current Google user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    return _googleSignIn.currentUser != null;
  }

  /// Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      print('✅ Disconnected Google account');
    } catch (e) {
      print('🔴 Error disconnecting Google account: $e');
    }
  }

  /// Silent sign in
  Future<GoogleAuthResult?> signInSilently() async {
    try {
      print('🔵 Attempting silent sign in...');
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      if (account == null) {
        print('⚠️ No previous sign in found');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      return GoogleAuthResult(
        id: account.id,
        name: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        serverAuthCode: auth.serverAuthCode,
      );
    } catch (e) {
      print('🔴 Silent sign in error: $e');
      return null;
    }
  }
}

class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);

  @override
  String toString() => 'GoogleAuthException: $message';
}