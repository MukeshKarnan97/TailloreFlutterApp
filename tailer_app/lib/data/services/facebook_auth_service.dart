import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthResult {
  final String? id;
  final String? name;
  final String? email;
  final String? picture;
  final Map<String, dynamic>? userData;
  final String? error;

  FacebookAuthResult({
    this.id,
    this.name,
    this.email,
    this.picture,
    this.userData,
    this.error,
  });

  bool get isSuccess => error == null && id != null;
}

class FacebookAuthService {
  static final FacebookAuthService _instance = FacebookAuthService._internal();
  factory FacebookAuthService() => _instance;
  FacebookAuthService._internal();

  /// Sign in with Facebook
  Future<FacebookAuthResult> signInWithFacebook() async {
    try {
      print('🔵 Starting Facebook Sign In');
      
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      print('🔵 Facebook Login Result Status: ${result.status}');

      if (result.status == LoginStatus.success) {
        // Get user data
        final userData = await FacebookAuth.instance.getUserData();
        print('🔵 Facebook User Data: $userData');

        return FacebookAuthResult(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          picture: userData['picture']?['data']?['url'],
          userData: userData,
        );
      } else if (result.status == LoginStatus.cancelled) {
        print('🔵 Facebook Sign In cancelled by user');
        return FacebookAuthResult(error: 'User cancelled Facebook login');
      } else {
        print('🔵 Facebook Sign In failed: ${result.message}');
        return FacebookAuthResult(error: result.message ?? 'Facebook login failed');
      }
    } catch (e) {
      print('🔴 Facebook Sign In Error: $e');
      return FacebookAuthResult(error: 'Facebook sign in failed: $e');
    }
  }

  /// Get current user data if logged in
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        return await FacebookAuth.instance.getUserData();
      }
      return null;
    } catch (e) {
      print('🔴 Get Facebook User Data Error: $e');
      return null;
    }
  }

  /// Sign out from Facebook
  Future<void> signOutFromFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      print('🔵 Facebook Sign Out successful');
    } catch (e) {
      print('🔴 Facebook Sign Out Error: $e');
    }
  }

  /// Check if user is currently logged in with Facebook
  Future<bool> isLoggedIn() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null;
    } catch (e) {
      print('🔴 Facebook isLoggedIn check error: $e');
      return false;
    }
  }

  /// Get current access token
  Future<AccessToken?> getAccessToken() async {
    try {
      return await FacebookAuth.instance.accessToken;
    } catch (e) {
      print('🔴 Get Facebook Access Token Error: $e');
      return null;
    }
  }
}