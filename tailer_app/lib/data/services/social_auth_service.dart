import 'google_auth_simple.dart';
import 'facebook_auth_service.dart';

class SocialAuthResult {
  final String? id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? provider;
  final Map<String, dynamic>? userData;
  final String? error;

  SocialAuthResult({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.provider,
    this.userData,
    this.error,
  });

  bool get isSuccess => error == null && id != null;
}

class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  final GoogleAuthService _googleAuth = GoogleAuthService();
  final FacebookAuthService _facebookAuth = FacebookAuthService();

  /// Sign in with Google
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final result = await _googleAuth.signInWithGoogle();
      
      if (result != null && result.isSuccess) {
        return SocialAuthResult(
          id: result.id,
          name: result.name,
          email: result.email,
          photoUrl: result.photoUrl,
          provider: 'google',
          userData: {
            'idToken': result.idToken,
            'accessToken': result.accessToken,
          },
        );
      } else {
        return SocialAuthResult(
          error: result?.error ?? 'Google sign in cancelled',
          provider: 'google',
        );
      }
    } catch (e) {
      return SocialAuthResult(
        error: 'Google sign in failed: $e',
        provider: 'google',
      );
    }
  }

  /// Sign in with Facebook
  Future<SocialAuthResult> signInWithFacebook() async {
    try {
      final result = await _facebookAuth.signInWithFacebook();
      
      if (result.isSuccess) {
        return SocialAuthResult(
          id: result.id,
          name: result.name,
          email: result.email,
          photoUrl: result.picture,
          provider: 'facebook',
          userData: result.userData,
        );
      } else {
        return SocialAuthResult(
          error: result.error ?? 'Facebook sign in failed',
          provider: 'facebook',
        );
      }
    } catch (e) {
      return SocialAuthResult(
        error: 'Facebook sign in failed: $e',
        provider: 'facebook',
      );
    }
  }

  /// Sign out from all social providers
  Future<void> signOutFromAll() async {
    await Future.wait([
      _googleAuth.signOutFromGoogle(),
      _facebookAuth.signOutFromFacebook(),
    ]);
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    await _googleAuth.signOutFromGoogle();
  }

  /// Sign out from Facebook
  Future<void> signOutFromFacebook() async {
    await _facebookAuth.signOutFromFacebook();
  }

  /// Check if user is signed in with any social provider
  Future<bool> isSignedIn() async {
    final googleSignedIn = _googleAuth.isSignedIn();
    final facebookSignedIn = await _facebookAuth.isLoggedIn();
    return googleSignedIn || facebookSignedIn;
  }

  /// Get current social provider
  Future<String?> getCurrentProvider() async {
    if (_googleAuth.isSignedIn()) {
      return 'google';
    } else if (await _facebookAuth.isLoggedIn()) {
      return 'facebook';
    }
    return null;
  }
}