import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  bool _isChanging = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChanging = true);
    final locale = AppLocalizations.of(_localeProvider.languageCode);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Verify current password
      final currentPasswordHash = sha256.convert(
        utf8.encode(_currentPasswordController.text)
      ).toString();

      // Get user from database to verify current password
      final users = await _dbService.select(
        'users',
        where: 'id = ? AND password_hash = ?',
        whereArgs: [currentUser.id, currentPasswordHash],
      );

      if (users.isEmpty) {
        throw Exception('Current password is incorrect');
      }

      // Hash new password
      final newPasswordHash = sha256.convert(
        utf8.encode(_newPasswordController.text)
      ).toString();

      // Update password in database
      await _dbService.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      Logger.info('ChangePasswordScreen', 'Password changed successfully');
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('passwordChanged'),
          customMessage: locale.translate('passwordChangedSuccessfully'),
          backgroundColor: Colors.green,
        );
        
        // Go back to settings
        context.pop();
      }
    } catch (e) {
      Logger.error('ChangePasswordScreen', 'Failed to change password', error: e);
      
      if (mounted) {
        String errorMessage = locale.translate('passwordChangeFailed');
        if (e.toString().contains('Current password is incorrect')) {
          errorMessage = locale.translate('currentPasswordIncorrect');
        }
        
        showNavigationMessage(
          context,
          locale.translate('changeFailed'),
          customMessage: errorMessage,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() => _isChanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              locale.translate('changePassword'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(AppConstants.primaryTeal),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityHeader(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildPasswordSection(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildSecurityTips(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildChangeButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityHeader() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Security Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.orange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.security_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('updateAccountPassword'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('passwordInformation'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Current Password field
          _buildPasswordField(
            controller: _currentPasswordController,
            label: locale.translate('currentPassword'),
            icon: Icons.lock_outline,
            showPassword: _showCurrentPassword,
            onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('currentPasswordRequired');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // New Password field
          _buildPasswordField(
            controller: _newPasswordController,
            label: locale.translate('newPassword'),
            icon: Icons.lock_reset_outlined,
            showPassword: _showNewPassword,
            onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('newPasswordRequired');
              }
              if (value.length < 6) {
                return locale.translate('passwordMinLength');
              }
              if (value == _currentPasswordController.text) {
                return locale.translate('newPasswordSameAsCurrent');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Confirm Password field
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: locale.translate('confirmNewPassword'),
            icon: Icons.lock_outlined,
            showPassword: _showConfirmPassword,
            onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return locale.translate('confirmPasswordRequired');
              }
              if (value != _newPasswordController.text) {
                return locale.translate('passwordsDoNotMatch');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(AppConstants.primaryTeal),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
        labelStyle: GoogleFonts.inter(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryTeal),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                locale.translate('securityTips'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(locale.translate('passwordTip1')),
          _buildTip(locale.translate('passwordTip2')),
          _buildTip(locale.translate('passwordTip3')),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeButton() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isChanging ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isChanging
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                locale.translate('changePassword'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}