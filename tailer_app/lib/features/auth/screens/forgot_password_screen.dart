import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthFooter.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';



class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(AppConstants.emailPattern);
    return emailRegex.hasMatch(email.trim());
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.emailRequiredError;
    }
    if (!_isEmailValid(value)) {
      return AppConstants.emailInvalidError;
    }
    return null;
  }

  Future<void> _validateAndSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.sendForgotPasswordEmail(_emailController.text.trim());

      if (success && mounted) {
        // Generate test OTP for debugging
        _authService.generateTestOTP();
        
        // Show success feedback with UserFeedbackService
        UserFeedbackService.showSuccess(
          context, 
          'Reset code sent to ${_emailController.text.trim()}'
        );

        // Navigate to OTP screen
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          context.pushNamed(RouteNames.otp,
            extra: {
              'firstTitle': 'VERIFICATION',
              'secondTitle': 'OTP',
              'emailText': 'Code sent to ${_emailController.text.trim()}',
              'email': _emailController.text.trim(),
              'onVerified': () {
                _navigateToPasswordReset();
              },
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle different types of errors with proper user feedback
        if (e is UserNotFoundException) {
          UserFeedbackService.showUserNotFound(context);
        } else if (e is NetworkException) {
          UserFeedbackService.showNetworkError(context);
        } else if (e is ValidationException) {
          final errorMessage = e.fieldErrors.values.join(', ');
          UserFeedbackService.showError(context, errorMessage);
        } else {
          // Handle generic exceptions
          final authEx = AuthExceptionHelper.fromException(e);
          UserFeedbackService.showError(context, 'Failed to send reset code: ${authEx.userMessage}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToPasswordReset() async {
    debugPrint('OTP verified successfully, navigating to password reset...');
    
    try {
      if (mounted) {
        UserFeedbackService.showSuccess(
          context,
          'OTP verified! Now set your new password.'
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          context.pushNamed(RouteNames.passwordReset, extra: {
            'email': _emailController.text.trim(),
          });
        }
      }
    } catch (error) {
      debugPrint('Navigation to password reset failed: $error');
      
      if (mounted) {
        UserFeedbackService.showError(
          context,
          'Navigation failed. Please try again.'
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
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
                const Center(child: AuthTitle(first: "FORGOT", second: "PASSWORD", fontSize: 24)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Let’s reset your password',
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
                    labelText: 'Email Address',
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
                // Reset button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : AuthButton(
                        text: "Send Reset Code",
                        onTap: _validateAndSubmit,
                      ),
                const SizedBox(height: 24),
                
                // Footer
                const AuthFooter(
                  text: "Remember your password? ",
                  actionText: "Sign In here",
                  route: "/auth/sign-in",
                ),
                const SizedBox(height: 40),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
