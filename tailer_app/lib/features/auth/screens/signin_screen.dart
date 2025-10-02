import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthFooter.dart';
import 'package:tailer_app/features/auth/widgets/AuthGoogleButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';
import 'package:tailer_app/data/services/social_auth_service.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';


class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _keepSignedIn = false;
  final AuthService _authService = AuthService();
  late SimpleLocaleProvider _localeProvider;

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(AppConstants.emailPattern);
    return emailRegex.hasMatch(email.trim());
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        // Call actual authentication service
        final success = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          keepSignedIn: _keepSignedIn,
        );
        
        if (mounted && success) {
          // Show success feedback with UserFeedbackService
          UserFeedbackService.showSignInSuccess(context, _emailController.text.trim());
          
          // Navigate to dashboard screen with comprehensive error handling
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            await _navigateToDashboard();
          }
        }
      } catch (e) {
        if (mounted) {
          // Handle different types of authentication errors with proper user feedback
          if (e is UserNotFoundException) {
            UserFeedbackService.showUserNotFound(context);
          } else if (e is InvalidCredentialsException) {
            UserFeedbackService.showInvalidCredentials(context);
          } else if (e is AccountLockedException) {
            UserFeedbackService.showAccountLocked(context);
          } else if (e is NetworkException) {
            UserFeedbackService.showNetworkError(context);
          } else if (e is ValidationException) {
            final errorMessage = e.fieldErrors.values.join(', ');
            UserFeedbackService.showError(context, errorMessage);
          } else {
            // Handle generic authentication exceptions
            final authEx = AuthExceptionHelper.fromException(e);
            UserFeedbackService.showError(context, authEx.userMessage);
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _navigateToDashboard() async {
    debugPrint('Starting navigation to dashboard...');
    
    try {
      debugPrint('Attempting GoRouter navigation...');
      context.goNamed(RouteNames.dashboard);
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

  Future<void> _handleForgotPassword() async {
    debugPrint('Forgot password clicked - navigating to forgot password screen');
    
    try {
      context.pushNamed(RouteNames.forgotPassword);
    } catch (e) {
      debugPrint('Navigation to forgot password failed: $e');
      
      if (mounted) {
        UserFeedbackService.showError(
          context,
          'Navigation failed. Please try again.',
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

  /// Handle successful social authentication
  void _handleSocialAuthSuccess(SocialAuthResult result) async {
    try {
      // Set "keep me logged in" based on user's current preference in the checkbox
      await _authService.setKeepLoggedIn(_keepSignedIn);
      
      UserFeedbackService.showSuccess(
        context, 
        'Welcome ${result.name}! Signed in with ${result.provider} successfully.'
      );
      
      // Navigate to dashboard after successful social auth
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.goNamed(RouteNames.dashboard);
        }
      });
    } catch (e) {
      print('Error setting keep logged in preference: $e');
      // Still show success and navigate, but log the error
      UserFeedbackService.showSuccess(
        context, 
        'Welcome ${result.name}! Signed in with ${result.provider} successfully.'
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // Don't dispose singleton _localeProvider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true, // 👈 important for keyboard
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
        child: Container(
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: AnimatedBuilder(
                animation: _localeProvider,
                builder: (context, _) {
                  return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                const SizedBox(height: 40),

                // Logo + Title
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
                // Center(child: richText(24)),
                const Center(child: AuthTitle(first: "SIGN", second: "IN", fontSize: 24)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppLocalizations.of(_localeProvider.languageCode).translate('signInSubtitle'),
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: const Color(0xFF969AA8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Google + Facebook
                // signInGoogleFacebookButton(size),
                SignUpGoogleFacebookButton(
                  size: size,
                  onSocialAuthSuccess: _handleSocialAuthSuccess,
                  onSocialAuthError: _handleSocialAuthError,
                ),
                const SizedBox(height: 24),

                // Email
                Semantics(
                  label: 'Email address input field',
                  child: ImprovedTextField(
                    controller: _emailController,
                    labelText: AppLocalizations.of(_localeProvider.languageCode).translate('emailAddress'),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocusNode,
                    onFieldSubmitted: (_) {
                      _passwordFocusNode.requestFocus();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.emailRequiredError;
                      }
                      if (!_isEmailValid(value)) {
                        return AppConstants.emailInvalidError;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                Semantics(
                  label: 'Password input field',
                  child: ImprovedTextField(
                    controller: _passwordController,
                    labelText: AppLocalizations.of(_localeProvider.languageCode).translate('password'),
                    prefixIcon: Icons.lock_outlined,
                    isPassword: true,
                    focusNode: _passwordFocusNode,
                    onFieldSubmitted: (_) {
                      _validateAndSubmit();
                    },
                    validator: _validatePassword,
                  ),
                ),
                const SizedBox(height: 16),

                // Keep signed in + Forgot
                keepSignedForgetSection(),
                const SizedBox(height: 24),

                // Sign In button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : AuthButton(
                        text: AppLocalizations.of(_localeProvider.languageCode).translate('signIn'),
                        onTap: _validateAndSubmit,
                      ),
                const SizedBox(height: 24),

                // Footer
                // buildFooter(context),
                AuthFooter(
                  text: AppLocalizations.of(_localeProvider.languageCode).translate('dontHaveAccount'),
                  actionText: AppLocalizations.of(_localeProvider.languageCode).translate('signUpHere'),
                  route: "/auth/sign-up",
                ),
                const SizedBox(height: 40),
              ],
                );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Keep signed in + forgot password
  Widget keepSignedForgetSection() {
    return Row(
      children: <Widget>[
        // Functional checkbox
        SizedBox(
          width: 20.0,
          height: 20.0,
          child: Checkbox(
            value: _keepSignedIn,
            onChanged: (value) {
              setState(() {
                _keepSignedIn = value ?? false;
              });
            },
            activeColor: const Color(0xFFF56B3F),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        // Clickable "Keep me signed in" text
        GestureDetector(
          onTap: () {
            setState(() {
              _keepSignedIn = !_keepSignedIn;
            });
          },
          child: Text(
            AppLocalizations.of(_localeProvider.languageCode).translate('keepMeSignedIn'),
            style: GoogleFonts.inter(
              fontSize: 12.0,
              color: Colors.black87,
            ),
          ),
        ),
        const Spacer(),
        // Clickable forgot password
        GestureDetector(
          onTap: _handleForgotPassword,
          child: Text(
            AppLocalizations.of(_localeProvider.languageCode).translate('forgotPassword'),
            style: GoogleFonts.inter(
              fontSize: 12.0,
              color: const Color(0xFFF56B3F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

}