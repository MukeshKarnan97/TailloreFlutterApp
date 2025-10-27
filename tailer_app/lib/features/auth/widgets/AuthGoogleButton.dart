import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/data/services/social_auth_service.dart';
import 'package:tailer_app/data/services/facebook_auth_service.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';

class SignUpGoogleFacebookButton extends StatelessWidget {
  final Size size;
  final Function(SocialAuthResult)? onSocialAuthSuccess;
  final Function(String)? onSocialAuthError;

  const SignUpGoogleFacebookButton({
    super.key, 
    required this.size,
    this.onSocialAuthSuccess,
    this.onSocialAuthError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        socialButton(
          size,
          'assets/google-2.svg',
          'Google',
          borderColor: const Color(0xFFDB4437), // Google red
          textColor: const Color(0xFF374151),
          onTap: () => _handleGoogleSignIn(context),
        ),
        const SizedBox(width: 16),
        socialButton(
          size,
          'assets/facebook-2.svg',
          'Facebook',
          borderColor: const Color(0xFF4267B2), // Facebook blue
          textColor: const Color(0xFF374151),
          onTap: () => _handleFacebookSignIn(context),
        ),
      ],
    );
  }

  /// Handle Google Sign In
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    print('');
    print('🚀 ========================================');
    print('🚀 GOOGLE SIGN-IN BUTTON CLICKED');
    print('🚀 Screen: SignUp Screen (AuthGoogleButton Widget)');
    print('🚀 Time: ${DateTime.now()}');
    print('🚀 ========================================');
    print('');
    
    try {
      print('🔵 Step 1: Creating SocialAuthService instance...');
      final socialAuth = SocialAuthService();
      
      print('🔵 Step 2: Calling SocialAuthService.signInWithGoogle()...');
      final result = await socialAuth.signInWithGoogle();
      
      print('🔵 Step 3: SocialAuthService returned result');
      print('   - Success: ${result.isSuccess}');
      print('   - Error: ${result.error ?? "None"}');
      print('   - Email: ${result.email ?? "None"}');
      print('   - Name: ${result.name ?? "None"}');
      
      if (result.isSuccess) {
        print('✅ Google sign-in successful! Calling success handler...');
        onSocialAuthSuccess?.call(result) ?? _defaultSuccessHandler(context, result);
        print('✅ Success handler completed');
      } else {
        print('❌ Google sign-in failed with error: ${result.error}');
        onSocialAuthError?.call(result.error ?? 'Google sign in failed') ?? 
            _defaultErrorHandler(context, result.error ?? 'Google sign in failed');
      }
    } catch (e, stackTrace) {
      print('');
      print('🔴 ==========================================');
      print('🔴 GOOGLE SIGN-IN EXCEPTION (AuthGoogleButton)');
      print('🔴 Error Type: ${e.runtimeType}');
      print('🔴 Error Message: $e');
      print('🔴 Stack Trace:');
      print('$stackTrace');
      print('🔴 ==========================================');
      print('');
      
      onSocialAuthError?.call(e.toString()) ?? _defaultErrorHandler(context, e.toString());
    }
  }

  /// Handle Facebook Sign In
  Future<void> _handleFacebookSignIn(BuildContext context) async {
    print('');
    print('🚀 ========================================');
    print('🚀 FACEBOOK SIGN-IN BUTTON CLICKED');
    print('🚀 Screen: ${context.widget.runtimeType}');
    print('🚀 Time: ${DateTime.now()}');
    print('🚀 ========================================');
    print('');
    
    try {
      print('🔵 Step 1: Creating SocialAuthService instance...');
      final socialAuth = SocialAuthService();
      
      print('🔵 Step 2: Calling SocialAuthService.signInWithFacebook()...');
      final result = await socialAuth.signInWithFacebook();
      
      print('🔵 Step 3: SocialAuthService returned result');
      print('   - Success: ${result.isSuccess}');
      print('   - Error: ${result.error ?? "None"}');
      print('   - Email: ${result.email ?? "None"}');
      print('   - Name: ${result.name ?? "None"}');
      print('   - ID: ${result.id ?? "None"}');
      
      if (result.isSuccess) {
        print('✅ Facebook sign-in successful! Calling success handler...');
        
        // Prepare userData with access token for HybridAuthService
        Map<String, dynamic> userData = result.userData != null 
            ? Map<String, dynamic>.from(result.userData!) 
            : <String, dynamic>{};
        
        print('   - Original UserData keys: ${userData.keys.toList()}');
        
        // Add userId to userData for HybridAuthService
        userData['userId'] = result.id ?? '';
        
        // Try to get Facebook access token
        try {
          final FacebookAuthService fbService = FacebookAuthService();
          final accessToken = await fbService.getAccessToken();
          if (accessToken != null) {
            userData['accessToken'] = accessToken.tokenString;
            print('   - Access token added: ${accessToken.tokenString.substring(0, 20)}...');
          } else {
            print('⚠️  Warning: Could not retrieve Facebook access token');
          }
        } catch (e) {
          print('⚠️  Warning: Error getting Facebook access token: $e');
        }
        
        print('   - Final UserData keys: ${userData.keys.toList()}');
        
        // Create new result with updated userData
        final updatedResult = SocialAuthResult(
          id: result.id,
          name: result.name,
          email: result.email,
          photoUrl: result.photoUrl,
          provider: result.provider,
          userData: userData,
        );
        
        onSocialAuthSuccess?.call(updatedResult) ?? _defaultSuccessHandler(context, updatedResult);
        print('✅ Success handler completed');
      } else {
        print('❌ Facebook sign-in failed with error: ${result.error}');
        onSocialAuthError?.call(result.error ?? 'Facebook sign in failed') ?? 
            _defaultErrorHandler(context, result.error ?? 'Facebook sign in failed');
      }
    } catch (e, stackTrace) {
      print('');
      print('🔴 ==========================================');
      print('🔴 FACEBOOK SIGN-IN EXCEPTION (AuthGoogleButton)');
      print('🔴 Error Type: ${e.runtimeType}');
      print('🔴 Error Message: $e');
      print('🔴 Stack Trace:');
      print('$stackTrace');
      print('🔴 ==========================================');
      print('');
      
      onSocialAuthError?.call(e.toString()) ?? _defaultErrorHandler(context, e.toString());
    }
  }

  /// Default success handler
  void _defaultSuccessHandler(BuildContext context, SocialAuthResult result) {
    UserFeedbackService.showSuccess(
      context, 
      'Welcome ${result.name}! Signed in successfully.'
    );
    
    // Navigate to dashboard
    Future.delayed(const Duration(milliseconds: 500), () {
      context.goNamed(RouteNames.dashboard);
    });
  }

  /// Default error handler
  void _defaultErrorHandler(BuildContext context, String error) {
    UserFeedbackService.showError(context, error);
  }

  /// Reusable Social Button
  Widget socialButton(
    Size size, 
    String assetPath, 
    String text, {
    Color borderColor = const Color(0xFFD1D5DB),
    Color textColor = const Color(0xFF374151),
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          debugPrint('$text button tapped');
        },
        borderRadius: BorderRadius.circular(12.0),
        splashColor: borderColor.withOpacity(0.1),
        highlightColor: borderColor.withOpacity(0.05),
        child: Container(
          alignment: Alignment.center,
          width: size.width / 2.8,
          height: size.height / 15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              width: 1.5, 
              color: const Color(0xFFD1D5DB), // More visible gray border
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(assetPath, width: 24, height: 24),
              const SizedBox(width: 10),
              Text(
                text, 
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600, // Make text more prominent
                  color: const Color(0xFF374151), // Darker text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
