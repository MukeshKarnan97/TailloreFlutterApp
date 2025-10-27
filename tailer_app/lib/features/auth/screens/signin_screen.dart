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
import 'package:tailer_app/features/debug/database_viewer_screen.dart';
import 'package:tailer_app/data/services/hybrid_auth_service.dart';
import 'package:tailer_app/data/models/tailor_model.dart';
import 'package:tailer_app/core/services/token_storage_service.dart';


class SignIn extends StatefulWidget {
  const SignIn({super.key});

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
  final HybridAuthService _hybridAuthService = HybridAuthService(); // For social auth
  final TokenStorageService _tokenStorage = TokenStorageService(); // For verification
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

  // ==================== SOCIAL AUTHENTICATION ====================
  // Social auth now handled by SignUpGoogleFacebookButton widget with callbacks
  // Old methods removed - callbacks are _handleSocialAuthSuccess and _handleSocialAuthError

  @override
  void initState() {
    super.initState();
    _localeProvider = SimpleLocaleProvider(); // Gets singleton instance
    // Screen loads without auto-focus to prevent automatic keyboard opening
  }

  /// Handle successful social authentication
  void _handleSocialAuthSuccess(SocialAuthResult result) async {
    print('');
    print('🎯 ========================================');
    print('🎯 SOCIAL AUTH SUCCESS CALLBACK (SignIn Screen)');
    print('🎯 Timestamp: ${DateTime.now().toIso8601String()}');
    print('🎯 Provider: ${result.provider ?? "unknown"}');
    print('🎯 Email: ${result.email ?? "none"}');
    print('🎯 Name: ${result.name ?? "none"}');
    print('🎯 Has userData: ${result.userData != null}');
    if (result.userData != null) {
      print('🎯 UserData keys: ${result.userData!.keys.toList()}');
    }
    print('🎯 ========================================');
    print('');

    try {
      // Extract provider
      final provider = result.provider?.toLowerCase() ?? '';
      final userData = result.userData ?? {};
      
      print('🔵 Step 1: Validating ${provider} authentication data...');
      
      // Validate we have an email
      final email = result.email;
      if (email == null || email.isEmpty) {
        throw Exception('No email provided by $provider authentication');
      }
      
      print('✅ Email validated: $email');
      print('');
      
      Tailor? tailor;
      
      // Call HybridAuthService based on provider
      // Backend will automatically:
      // - Check if user exists (returns isNewUser = false)
      // - Create new user if needed (returns isNewUser = true)
      // - Return JWT tokens in both cases
      if (provider == 'google') {
        print('🔵 Step 2: Calling HybridAuthService.signInWithGoogle()...');
        print('   - This will check if user exists in backend');
        print('   - If exists: Direct login');
        print('   - If not: Auto sign-up + login');
        print('');
        
        tailor = await _hybridAuthService.signInWithGoogle(
          idToken: userData['idToken']!,
          accessToken: userData['accessToken'],
          serverAuthCode: userData['serverAuthCode'],
        );
        
        print('');
        print('✅ Google authentication completed!');
        print('   - User ID: ${tailor.id}');
        print('   - Email: ${tailor.email}');
        print('   - Name: ${tailor.name}');
        print('   - Shop: ${tailor.shopName}');
        print('');
        
      } else if (provider == 'facebook') {
        print('🔵 Step 2: Calling HybridAuthService.signInWithFacebook()...');
        print('   - This will check if user exists in backend');
        print('   - If exists: Direct login');
        print('   - If not: Auto sign-up + login');
        print('');
        
        tailor = await _hybridAuthService.signInWithFacebook(
          accessToken: userData['accessToken']!,
          userId: userData['userId'] ?? '',
        );
        
        print('');
        print('✅ Facebook authentication completed!');
        print('   - User ID: ${tailor.id}');
        print('   - Email: ${tailor.email}');
        print('   - Name: ${tailor.name}');
        print('   - Shop: ${tailor.shopName}');
        print('');
        
      } else {
        throw Exception('Unknown provider: $provider');
      }
      
      print('🔵 Step 3: Verifying authentication state...');
      
      // Verify tokens were saved
      final accessToken = await _tokenStorage.getAccessToken();
      final savedEmail = await _tokenStorage.getUserEmail();
      
      print('   - Has access token: ${accessToken != null && accessToken.isNotEmpty}');
      print('   - Saved email: ${savedEmail ?? "none"}');
      print('');
      
      if (accessToken == null || accessToken.isEmpty) {
        print('⚠️  WARNING: Access token not saved properly!');
      }
      
      print('🔵 Step 4: Setting user preferences...');
      
      // Set "keep me logged in" based on user's current preference in the checkbox
      await _authService.setKeepLoggedIn(_keepSignedIn);
      
      print('   - Keep me logged in: $_keepSignedIn');
      print('');
      
      print('🔵 Step 5: Showing success feedback...');
      
      UserFeedbackService.showSuccess(
        context, 
        'Welcome ${result.name}! Signed in with ${result.provider} successfully.'
      );
      
      print('✅ Success message displayed');
      print('');
      
      // Navigate to dashboard after successful social auth
      print('🔵 Step 6: Navigating to dashboard...');
      
      final authenticatedEmail = tailor.email; // Capture email for closure
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.goNamed(RouteNames.dashboard);
          print('✅ Navigation to dashboard initiated');
          print('');
          print('🎉 ========================================');
          print('🎉 SOCIAL AUTH SIGN-IN COMPLETE!');
          print('🎉 User: $authenticatedEmail');
          print('🎉 Timestamp: ${DateTime.now().toIso8601String()}');
          print('🎉 ========================================');
          print('');
        } else {
          print('⚠️  WARNING: Widget not mounted, navigation skipped');
        }
      });
      
    } catch (e, stackTrace) {
      print('');
      print('🔴 ==========================================');
      print('🔴 SOCIAL AUTH ERROR (SignIn Screen)');
      print('🔴 Timestamp: ${DateTime.now().toIso8601String()}');
      print('🔴 Error Type: ${e.runtimeType}');
      print('🔴 Error Message: $e');
      print('🔴 ==========================================');
      print('🔴 Stack Trace:');
      print('$stackTrace');
      print('🔴 ==========================================');
      print('');
      
      UserFeedbackService.showError(
        context, 
        'Authentication failed: ${e.toString()}'
      );
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
      floatingActionButton: Stack(
        children: [
          // Language Selector Button (bottom right)
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
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
          ),
          
          // Debug Database Button (bottom left)
          Positioned(
            left: 16,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'debug_db',
              mini: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DatabaseViewerScreen(),
                  ),
                );
              },
              child: const Icon(Icons.bug_report, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(33, 137, 156, 0.5),
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
                Center(
                  child: Builder(
                    builder: (context) {
                      final signInTitle = AppLocalizations.of(_localeProvider.languageCode).translate('signInTitle');
                      final titleParts = signInTitle.split(' ');
                      final firstWord = titleParts.isNotEmpty ? titleParts[0] : 'SIGN';
                      final secondWord = titleParts.length > 1 ? titleParts.sublist(1).join(' ') : 'IN';
                      
                      return AuthTitle(
                        first: firstWord,
                        second: secondWord,
                        fontSize: 24,
                      );
                    },
                  ),
                ),
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

                // OR Divider
                // Row(
                //   children: [
                //     Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Text(
                //         'OR',
                //         style: GoogleFonts.poppins(
                //           color: Colors.grey[600],
                //           fontSize: 14,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ),
                //     Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                //   ],
                // ),
                // const SizedBox(height: 24),

                // Google Sign In Button
                // _isGoogleLoading
                //     ? const Center(child: CircularProgressIndicator())
                //     : _buildGoogleButton(),
                // const SizedBox(height: 16),

                // // Facebook Sign In Button
                // _isFacebookLoading
                //     ? const Center(child: CircularProgressIndicator())
                //     : _buildFacebookButton(),
                // const SizedBox(height: 24),

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
