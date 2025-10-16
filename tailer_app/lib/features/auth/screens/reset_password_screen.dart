import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/hybrid_auth_service.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/ImprovedTextField.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'dart:async';

/// Reset Password Screen - Enter OTP and new password
class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? resetToken; // Token from forgot password API

  const ResetPasswordScreen({
    super.key,
    this.email,
    this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final HybridAuthService _hybridAuth = HybridAuthService();
  
  // OTP Controllers (4 digits)
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  // Password Controllers
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  
  bool _isLoading = false;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    
    // Debug logging
    debugPrint('=== Reset Password Screen Initialized ===');
    debugPrint('Email received: ${widget.email}');
    debugPrint('Reset token received: ${widget.resetToken}');
    debugPrint('Token is null: ${widget.resetToken == null}');
    debugPrint('Token is empty: ${widget.resetToken?.isEmpty ?? true}');
    if (widget.resetToken != null) {
      debugPrint('Token length: ${widget.resetToken!.length}');
      debugPrint('Token value: ${widget.resetToken!.substring(0, 20)}...');
    }
    debugPrint('=====================================');
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_otpCode.length != 4) {
      UserFeedbackService.showError(context, 'Please enter the complete 4-digit OTP code');
      return;
    }

    if (widget.email == null || widget.email!.isEmpty) {
      debugPrint('ERROR: Email is null or empty');
      UserFeedbackService.showError(context, 'Email not provided');
      return;
    }

    if (widget.resetToken == null || widget.resetToken!.isEmpty) {
      debugPrint('ERROR: Reset token is null or empty');
      debugPrint('Token null: ${widget.resetToken == null}');
      debugPrint('Token empty: ${widget.resetToken?.isEmpty}');
      UserFeedbackService.showError(
        context, 
        'Reset token not provided. Please start from forgot password.\n'
        'Debug: token=${widget.resetToken?.substring(0, 10) ?? "NULL"}'
      );
      return;
    }
    
    debugPrint('✅ Validation passed - Email: ${widget.email}, Token: ${widget.resetToken!.substring(0, 20)}...');

    setState(() => _isLoading = true);

    try {
      await _hybridAuth.resetPasswordWithOTP(
        email: widget.email!,
        otpCode: _otpCode,
        newPassword: _newPasswordController.text,
        newPasswordConfirm: _confirmPasswordController.text,
        resetToken: widget.resetToken!,
      );

      if (mounted) {
        // Show success message
        UserFeedbackService.showSuccess(
          context,
          'Password reset successful! Please sign in with your new password.',
        );

        // Wait a moment then navigate to sign in
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          context.goNamed(RouteNames.signIn);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        UserFeedbackService.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UserFeedbackService.showError(
          context,
          'Password reset failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOTP() async {
    if (_resendTimer > 0) return;
    if (widget.email == null || widget.email!.isEmpty) return;

    try {
      await _hybridAuth.requestPasswordReset(widget.email!);
      if (mounted) {
        UserFeedbackService.showSuccess(
          context,
          'New OTP sent to your email',
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        UserFeedbackService.showError(
          context,
          'Failed to resend OTP. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF21899C)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo2.svg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Reset Your Password',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF21899C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Enter the code sent to',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF21899C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // OTP Input Section
                Text(
                  'Verification Code (4 digits)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // OTP Fields (4 digits)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: size.width / 6,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF21899C),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF21899C),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            _otpFocusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Resend OTP
                Center(
                  child: TextButton(
                    onPressed: _resendTimer == 0 ? _handleResendOTP : null,
                    child: Text(
                      _resendTimer > 0
                          ? 'Resend code in $_resendTimer s'
                          : 'Resend Code',
                      style: GoogleFonts.inter(
                        color: _resendTimer > 0
                            ? Colors.grey
                            : const Color(0xFF21899C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // New Password Section
                Text(
                  'New Password',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // New Password Field
                ImprovedTextField(
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocus,
                  labelText: 'Enter new password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                ImprovedTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  labelText: 'Confirm new password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 32),

                // Submit Button
                AuthButton(
                  text: 'Reset Password',
                  onTap: _isLoading ? null : _handleResetPassword,
                ),
                const SizedBox(height: 16),

                // Back to Sign In
                Center(
                  child: TextButton(
                    onPressed: () => context.goNamed(RouteNames.signIn),
                    child: Text(
                      'Back to Sign In',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF21899C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
