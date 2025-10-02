import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/services/user_feedback_service.dart';
import 'package:tailer_app/core/exceptions/auth_exceptions.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';

class VerificationScreen extends StatefulWidget {
  final String firstTitle;
  final String secondTitle;
  final String emailText;
  final String? email;
  final VoidCallback onVerified;

  const VerificationScreen({
    super.key,
    required this.firstTitle,
    required this.secondTitle,
    required this.emailText,
    this.email,
    required this.onVerified,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: LogoWithTitle(
            firstTitle: locale.translate('verificationTitle'),
            secondTitle: locale.translate('otpTitle'),
            subText: locale.translate('emailVerificationSent'),
            children: [
              Text(
                widget.emailText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              OtpForm(
                onVerified: widget.onVerified,
                email: widget.email ?? 'test@example.com',
              ),
            ],
          ),
        );
      },
    );
  }
}

class OtpForm extends StatefulWidget {
  final VoidCallback onVerified;
  final String email;
  const OtpForm({super.key, required this.onVerified, required this.email});

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  late FocusNode _pin1Node;
  late FocusNode _pin2Node;
  late FocusNode _pin3Node;
  late FocusNode _pin4Node;

  final TextEditingController _pin1Controller = TextEditingController();
  final TextEditingController _pin2Controller = TextEditingController();
  final TextEditingController _pin3Controller = TextEditingController();
  final TextEditingController _pin4Controller = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  
  // Timer variables for resend OTP
  Timer? _resendTimer;
  int _resendCountdown = 180; // 3 minutes = 180 seconds
  bool _canResend = false;
  String _currentOTP = '1234'; // Store current OTP

  @override
  void initState() {
    super.initState();
    _pin1Node = FocusNode();
    _pin2Node = FocusNode();
    _pin3Node = FocusNode();
    _pin4Node = FocusNode();
    _startResendTimer();
    // Generate initial OTP
    _generateNewOTP();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pin1Node.dispose();
    _pin2Node.dispose();
    _pin3Node.dispose();
    _pin4Node.dispose();
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    _pin3Controller.dispose();
    _pin4Controller.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _resendCountdown = 180; // Reset to 3 minutes
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _generateNewOTP() async {
    try {
      // Use auth service to send OTP to email
      _currentOTP = await _authService.sendOTPToEmail(widget.email);
      debugPrint('🔐 New OTP Generated for ${widget.email}: $_currentOTP');
    } catch (e) {
      // Fallback to local generation if service fails
      final random = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
      _currentOTP = random.toString();
      debugPrint('🔐 Fallback OTP Generated: $_currentOTP');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      // Generate new OTP using auth service
      await _generateNewOTP();
      
      if (mounted) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        UserFeedbackService.showSuccess(
          context,
          '${locale.translate('newOTPSent')} ${widget.email}'
        );
        
        // Clear previous OTP input
        _pin1Controller.clear();
        _pin2Controller.clear();
        _pin3Controller.clear();
        _pin4Controller.clear();
        
        // Focus on first field
        _pin1Node.requestFocus();
        
        // Restart timer
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        UserFeedbackService.showError(
          context,
          locale.translate('failedToResendOTP')
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _pin1Controller.text + _pin2Controller.text + _pin3Controller.text + _pin4Controller.text;
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    if (otp.length != 4) {
      setState(() {
        _errorMessage = locale.translate('pleaseEnterCompleteOTP');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use auth service for OTP verification
      final isValid = await _authService.verifyOTP(otp, widget.email);
      
      // Also check against current generated OTP for development
      final isDevelopmentOTP = (otp == _currentOTP || otp == '1234');
      
      if (isValid || isDevelopmentOTP) {
        if (mounted) {
          UserFeedbackService.showSuccess(
            context,
            locale.translate('otpVerifiedSuccessfully')
          );
          
          // Cancel timer when verification is successful
          _resendTimer?.cancel();
          
          // Small delay for user feedback
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            widget.onVerified();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = locale.translate('invalidOTP');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = locale.translate('verificationFailed');
        
        if (e is AuthException) {
          errorMsg = e.userMessage;
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
        
        UserFeedbackService.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: OtpTextFormField(
                      controller: _pin1Controller,
                      focusNode: _pin1Node,
                      autofocus: false,
                      onChanged: (value) {
                        if (value.length == 1) _pin2Node.requestFocus();
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: OtpTextFormField(
                      controller: _pin2Controller,
                      focusNode: _pin2Node,
                      onChanged: (value) {
                        if (value.length == 1) _pin3Node.requestFocus();
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: OtpTextFormField(
                      controller: _pin3Controller,
                      focusNode: _pin3Node,
                      onChanged: (value) {
                        if (value.length == 1) _pin4Node.requestFocus();
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: OtpTextFormField(
                      controller: _pin4Controller,
                      focusNode: _pin4Node,
                      onChanged: (value) {
                        if (value.length == 1) _pin4Node.unfocus();
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              
              // Resend OTP Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locale.translate('didntReceiveCode'),
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_canResend)
                    GestureDetector(
                      onTap: _isResending ? null : _resendOTP,
                      child: Text(
                        _isResending ? locale.translate('sending') : locale.translate('resendOTP'),
                        style: GoogleFonts.inter(
                          fontSize: 14.0,
                          color: _isResending ? Colors.grey : const Color(0xFFF56B3F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      "${locale.translate('resendIn')} ${_formatTime(_resendCountdown)}",
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16.0),
              
              // Development Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      '${locale.translate('developmentOTP')}: $_currentOTP',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.translate('fallbackOTP'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Verify Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : AuthButton(
                      text: locale.translate('verifyOTP'),
                      onTap: _verifyOTP,
                    ),
            ],
          ),
        );
      },
    );
  }
}

class OtpTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const OtpTextFormField({
    Key? key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller?.text.isNotEmpty == true 
            ? Colors.indigo.shade600 
            : Colors.black54,
          width: controller?.text.isNotEmpty == true ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        focusNode: focusNode,
        onChanged: onChanged,
        obscureText: true,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(
            fontSize: 24,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class LogoWithTitle extends StatelessWidget {
  final String firstTitle, secondTitle, subText;
  final List<Widget> children;

  const LogoWithTitle({
    Key? key,
    required this.firstTitle,
    required this.secondTitle,
    this.subText = '',
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient container up to subText
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(33, 137, 156, 0.15),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  LogoWidget(height_: size.height / 8, width_: size.height / 8),
                  const SizedBox(height: 24),

                  // Title
                  Builder(
                    builder: (context) {
                      // Combine first and second title for word splitting
                      final fullTitle = '$firstTitle $secondTitle'.trim();
                      final words = fullTitle.split(' ');
                      return AuthTitle(
                        first: words.isNotEmpty ? words.first : firstTitle,
                        second: words.length > 1 ? words.sublist(1).join(' ') : secondTitle,
                        fontSize: 24,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subtext
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      subText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.64),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // OTP fields and other children
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}