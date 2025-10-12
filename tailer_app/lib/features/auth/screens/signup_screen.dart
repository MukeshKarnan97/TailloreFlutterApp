import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthFooter.dart';
import 'package:tailer_app/features/auth/widgets/AuthGoogleButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';
import 'package:tailer_app/data/services/social_auth_service.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  late SimpleLocaleProvider _localeProvider;
  
  bool _isLoading = false;
  String? _emailExistsError;

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    return emailRegex.hasMatch(email.trim());
  }

  String? _validateUsername(String? value) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    if (value == null || value.trim().isEmpty) {
      return locale.translate('nameRequired');
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    if (value == null || value.trim().isEmpty) {
      return locale.translate('fieldRequired');
    }
    if (!_isEmailValid(value)) {
      return locale.translate('invalidEmail');
    }
    // Return cached email exists error if present
    if (_emailExistsError != null && value.trim() == _emailController.text.trim()) {
      return _emailExistsError;
    }
    return null;
  }

  Future<void> _checkEmailExists(String email) async {
    if (email.trim().isEmpty || !_isEmailValid(email)) return;
    
    setState(() {
      _emailExistsError = null;
    });

    try {
      final exists = await _authService.checkEmailExists(email.trim());
      if (mounted) {
        setState(() {
          _emailExistsError = exists ? 'Email already exists. Please use a different email or sign in.' : null;
        });
      }
    } catch (e) {
      // Error checking email - we'll just let validation continue
      print('Error checking email existence: $e');
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredError;
    }
    if (value.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordLengthError;
    }
    // Check for at least one uppercase letter, one lowercase letter, and one number
    if (!RegExp(AppConstants.passwordPattern).hasMatch(value)) {
      return AppConstants.passwordComplexityError;
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
      await _authService.signUpNewUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${_usernameController.text.trim()}! Please verify your email.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to OTP screen for email verification
        await _navigateToOTP();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _navigateToOTP() async {
    debugPrint('Starting navigation to OTP screen after signup...');
    
    try {
      debugPrint('Attempting GoRouter navigation to OTP...');
      context.pushNamed(
        RouteNames.otp,
        extra: {
          'firstTitle': 'Verification',
          'secondTitle': 'OTP',
          'emailText': _emailController.text,
          'email': _emailController.text,
          'onVerified': () async {
            // Sign in the user after successful signup verification
            debugPrint('OTP verified, signing in user...');
            try {
              await _authService.signIn(
                email: _emailController.text,
                password: _passwordController.text,
                keepSignedIn: true,
              );
              debugPrint('User signed in successfully, navigating to dashboard...');
              // Navigate to dashboard after successful sign in
              if (mounted) {
                context.goNamed(RouteNames.dashboard);
              }
            } catch (e) {
              debugPrint('Auto sign-in failed: $e');
              // If sign-in fails, still navigate to dashboard
              // The dashboard will handle the not-authenticated state
              if (mounted) {
                context.goNamed(RouteNames.dashboard);
              }
            }
          },
        },
      );
      debugPrint('GoRouter navigation successful');
    } catch (error) {
      debugPrint('Navigation failed: $error');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed. Please try again. Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handle successful social authentication
  void _handleSocialAuthSuccess(SocialAuthResult result) async {
    try {
      UserFeedbackService.showSuccess(
        context, 
        'Welcome ${result.name}! Signed up with ${result.provider} successfully.'
      );
      
      // Navigate to dashboard after successful social auth signup
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.goNamed(RouteNames.dashboard);
        }
      });
    } catch (e) {
      print('Error after social auth signup: $e');
      // Still show success and navigate, but log the error
      UserFeedbackService.showSuccess(
        context, 
        'Welcome ${result.name}! Signed up with ${result.provider} successfully.'
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.goNamed(RouteNames.dashboard);
        }
      });
    }
  }

  /// Handle social authentication error
  void _handleSocialAuthError(String error) {
    UserFeedbackService.showError(context, error);
  }

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider(); // Gets singleton instance
    // Screen loads without auto-focus to prevent automatic keyboard opening
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // Don't dispose singleton _localeProvider
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
                    Color.fromRGBO(33, 137, 156, 0.15),
                    Colors.white,
                    Colors.white,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 30),
                      Center(
                        child: Semantics(
                          label: 'Tailor app logo',
                          child: LogoWidget(
                            height_: size.height / 8, 
                            width_: size.height / 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Builder(
                          builder: (context) {
                            final signUpTitle = locale.translate('signUpTitle');
                            final words = signUpTitle.split(' ');
                            return AuthTitle(
                              first: words.isNotEmpty ? words.first : signUpTitle,
                              second: words.length > 1 ? words.sublist(1).join(' ') : "",
                              fontSize: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          locale.translate('signUpSubtitle'),
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            color: const Color(0xFF969AA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SignUpGoogleFacebookButton(
                        size: size,
                        onSocialAuthSuccess: _handleSocialAuthSuccess,
                        onSocialAuthError: _handleSocialAuthError,
                      ),
                      const SizedBox(height: 20),
                      
                      // Username
                      Semantics(
                        label: 'Username input field',
                        child: ImprovedTextField(
                          controller: _usernameController,
                          labelText: locale.translate('username'),
                          prefixIcon: Icons.person_outlined,
                          focusNode: _usernameFocusNode,
                          onFieldSubmitted: (_) {
                            _emailFocusNode.requestFocus();
                          },
                          validator: _validateUsername,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      Semantics(
                        label: 'Email address input field',
                        child: ImprovedTextField(
                          controller: _emailController,
                          labelText: locale.translate('emailAddress'),
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocusNode,
                          onChanged: (value) {
                            if (_emailExistsError != null) {
                              setState(() { _emailExistsError = null; });
                            }
                            Future.delayed(const Duration(milliseconds: 800), () {
                              if (_emailController.text.trim() == value.trim() && value.trim().isNotEmpty && _isEmailValid(value.trim())) {
                                _checkEmailExists(value.trim());
                              }
                            });
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                          validator: _validateEmail,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      Semantics(
                        label: 'Password input field',
                        child: ImprovedTextField(
                          controller: _passwordController,
                          labelText: locale.translate('password'),
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          focusNode: _passwordFocusNode,
                          onFieldSubmitted: (_) {
                            _validateAndSubmit();
                          },
                          validator: _validatePassword,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : AuthButton(
                              text: locale.translate('signUp'),
                              onTap: _validateAndSubmit,
                            ),
                      const SizedBox(height: 20),
                      AuthFooter(
                        text: locale.translate('alreadyHaveAccount'),
                        actionText: locale.translate('signInHere'),
                        route: "/auth/sign-in",
                      ),
                      const SizedBox(height: 30),
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