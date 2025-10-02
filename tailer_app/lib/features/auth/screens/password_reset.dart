import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';

class PasswordReset extends StatefulWidget {
  final String? email;
  
  const PasswordReset({Key? key, this.email}) : super(key: key);

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredError;
    }
    if (value.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordLengthError;
    }
    if (!RegExp(AppConstants.passwordPattern).hasMatch(value)) {
      return AppConstants.passwordComplexityError;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final success = await _authService.resetPassword(
          newPassword: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          email: widget.email,
        );
        
        if (mounted && success) {
          UserFeedbackService.showSuccess(
            context,
            'Password reset successful! Please sign in with your new password.'
          );
          
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (mounted) {
            context.goNamed(RouteNames.signIn);
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = 'Password reset failed. Please try again.';
          
          if (e is AuthException) {
            errorMsg = e.userMessage;
          } else if (e is ValidationException) {
            errorMsg = e.fieldErrors.values.join(', ');
          }
          
          UserFeedbackService.showError(context, errorMsg);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 40),

                  Center(
                    child: LogoWidget(
                      height_: size.height / 8, 
                      width_: size.height / 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: AuthTitle(first: "RESET", second: "PASSWORD", fontSize: 24)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Enter your new password',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        color: const Color(0xFF969AA8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (widget.email != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Resetting password for: ${widget.email}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  ImprovedTextField(
                    controller: _passwordController,
                    labelText: 'New Password',
                    prefixIcon: Icons.lock_outlined,
                    isPassword: true,
                    focusNode: _passwordFocusNode,
                    onFieldSubmitted: (_) {
                      _confirmPasswordFocusNode.requestFocus();
                    },
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  
                  ImprovedTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_outlined,
                    isPassword: true,
                    focusNode: _confirmPasswordFocusNode,
                    onFieldSubmitted: (_) {
                      _validateAndSubmit();
                    },
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 24),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AuthButton(
                          text: "Reset Password",
                          onTap: _validateAndSubmit,
                        ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.goNamed(RouteNames.signIn);
                      },
                      child: Text(
                        'Back to Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFF56B3F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
