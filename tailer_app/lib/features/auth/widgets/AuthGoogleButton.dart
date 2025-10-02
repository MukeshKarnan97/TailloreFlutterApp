import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/data/services/social_auth_service.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';

class SignUpGoogleFacebookButton extends StatelessWidget {
  final Size size;
  final Function(SocialAuthResult)? onSocialAuthSuccess;
  final Function(String)? onSocialAuthError;

  const SignUpGoogleFacebookButton({
    Key? key, 
    required this.size,
    this.onSocialAuthSuccess,
    this.onSocialAuthError,
  }) : super(key: key);

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
    try {
      final socialAuth = SocialAuthService();
      final result = await socialAuth.signInWithGoogle();
      
      if (result.isSuccess) {
        onSocialAuthSuccess?.call(result) ?? _defaultSuccessHandler(context, result);
      } else {
        onSocialAuthError?.call(result.error ?? 'Google sign in failed') ?? 
            _defaultErrorHandler(context, result.error ?? 'Google sign in failed');
      }
    } catch (e) {
      onSocialAuthError?.call(e.toString()) ?? _defaultErrorHandler(context, e.toString());
    }
  }

  /// Handle Facebook Sign In
  Future<void> _handleFacebookSignIn(BuildContext context) async {
    try {
      final socialAuth = SocialAuthService();
      final result = await socialAuth.signInWithFacebook();
      
      if (result.isSuccess) {
        onSocialAuthSuccess?.call(result) ?? _defaultSuccessHandler(context, result);
      } else {
        onSocialAuthError?.call(result.error ?? 'Facebook sign in failed') ?? 
            _defaultErrorHandler(context, result.error ?? 'Facebook sign in failed');
      }
    } catch (e) {
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
