import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/hybrid_auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthFooter.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final HybridAuthService _hybridAuth = HybridAuthService();
  late SimpleLocaleProvider _localeProvider;
  bool _isLoading = false;

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(AppConstants.emailPattern);
    return emailRegex.hasMatch(email.trim());
  }

  String? _validateEmail(String? value) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    if (value == null || value.isEmpty) {
      return locale.translate('fieldRequired');
    }
    if (!_isEmailValid(value)) {
      return locale.translate('invalidEmail');
    }
    return null;
  }

  Future<void> _validateAndSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to send OTP and get reset token
      final resetToken = await _hybridAuth.requestPasswordReset(_emailController.text.trim());

      if (mounted) {
        // Show success message
        UserFeedbackService.showSuccess(
          context,
          'OTP sent to your email! Please check your inbox.',
        );

        // Navigate to reset password screen with OTP input and reset token
        await _navigateToResetPassword(resetToken);
      }
    } on AuthException catch (e) {
      if (mounted) {
        UserFeedbackService.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UserFeedbackService.showError(
          context,
          'Failed to send OTP. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToResetPassword(String resetToken) async {
    debugPrint('=== Navigating to Reset Password ===');
    debugPrint('Email: ${_emailController.text.trim()}');
    debugPrint('Reset token: $resetToken');
    debugPrint('Token length: ${resetToken.length}');
    debugPrint('Token first 20 chars: ${resetToken.substring(0, 20)}');
    
    final navData = {
      'email': _emailController.text.trim(),
      'resetToken': resetToken,
    };
    debugPrint('Navigation data: $navData');
    debugPrint('Data keys: ${navData.keys}');
    debugPrint('===================================');
    
    try {
      context.pushNamed(
        RouteNames.resetPassword,
        extra: navData,
      );
      debugPrint('✅ Navigation call completed');
    } catch (error) {
      debugPrint('❌ Navigation failed: $error');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider(); // Gets singleton instance
    // Screen loads without auto-focus to prevent automatic keyboard opening
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: AnimatedBuilder(
        animation: _localeProvider,
        builder: (context, _) {
          // Get current language details
          final currentLanguage = AppLocalizations.availableLanguages
              .firstWhere(
                (lang) => lang.code == _localeProvider.languageCode,
                orElse: () => AppLocalizations.availableLanguages.first,
              );
          
          return Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF21899C),
                  Color(0xFF1A7A8A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF21899C).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.pushNamed(RouteNames.languageSelection);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentLanguage.flag,
                        style: const TextStyle(
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(0.5, 0.5),
                              blurRadius: 1.0,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentLanguage.isoCode,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            const Shadow(
                              offset: Offset(0.5, 0.5),
                              blurRadius: 1.0,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _localeProvider,
          builder: (context, _) {
            final locale = AppLocalizations.of(_localeProvider.languageCode);
            
            return Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(33, 137, 156, 0.5),
                    Colors.white,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 100),
                      Center(child: LogoWidget(height_: size.height / 8, width_:size.height / 8)),
                      const SizedBox(height: 60),
                      Center(
                        child: Builder(
                          builder: (context) {
                            final forgotPasswordTitle = locale.translate('forgotPasswordTitle');
                            final words = forgotPasswordTitle.split(' ');
                            return AuthTitle(
                              first: words.isNotEmpty ? words.first : forgotPasswordTitle,
                              second: words.length > 1 ? words.sublist(1).join(' ') : "",
                              fontSize: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          locale.translate('forgotPasswordSubtitle'),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: const Color(0xFF969AA8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Email
                      Semantics(
                        label: 'Email address input field',
                        child: ImprovedTextField(
                          controller: _emailController,
                          labelText: locale.translate('emailAddress'),
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocusNode,
                          onFieldSubmitted: (_) {
                            _validateAndSubmit();
                          },
                          validator: _validateEmail,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : AuthButton(
                              text: locale.translate('resetPassword'),
                              onTap: _validateAndSubmit,
                            ),
                      const SizedBox(height: 20),
                      AuthFooter(
                        text: locale.translate('rememberPassword'),
                        actionText: locale.translate('signInHere'),
                        route: "/auth/sign-in",
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}