import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  bool _isLoading = true;
  bool _biometricAuth = false;
  bool _autoLock = true;
  bool _dataEncryption = true;
  bool _analyticsTracking = false;
  bool _crashReporting = true;
  bool _personalizedAds = false;
  bool _locationTracking = false;
  String _autoLockDuration = '5'; // minutes

  final List<Map<String, String>> _lockDurations = [
    {'value': '1', 'label': '1 minute'},
    {'value': '5', 'label': '5 minutes'},
    {'value': '10', 'label': '10 minutes'},
    {'value': '30', 'label': '30 minutes'},
    {'value': '60', 'label': '1 hour'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _biometricAuth = prefs.getBool('biometric_auth') ?? false;
        _autoLock = prefs.getBool('auto_lock') ?? true;
        _dataEncryption = prefs.getBool('data_encryption') ?? true;
        _analyticsTracking = prefs.getBool('analytics_tracking') ?? false;
        _crashReporting = prefs.getBool('crash_reporting') ?? true;
        _personalizedAds = prefs.getBool('personalized_ads') ?? false;
        _locationTracking = prefs.getBool('location_tracking') ?? false;
        _autoLockDuration = prefs.getString('auto_lock_duration') ?? '5';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      // Handle error silently or show message
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
              locale.translate('privacySecurity'),
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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrivacyHeader(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildSecuritySection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildPrivacySection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildDataSection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPrivacyHeader() {
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.purple.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.security_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('secureYourData'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('managePrivacySettings'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('security'),
      icon: Icons.lock_outline,
      children: [
        _buildSwitchTile(
          title: locale.translate('biometricAuthentication'),
          subtitle: locale.translate('useFingerprintFaceId'),
          value: _biometricAuth,
          onChanged: (value) {
            setState(() => _biometricAuth = value);
            _saveSetting('biometric_auth', value);
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('autoLock'),
          subtitle: locale.translate('lockAppAfterInactivity'),
          value: _autoLock,
          onChanged: (value) {
            setState(() => _autoLock = value);
            _saveSetting('auto_lock', value);
          },
        ),
        if (_autoLock) ...[
          _buildDivider(),
          _buildDropdownTile(
            title: locale.translate('autoLockDuration'),
            subtitle: locale.translate('timeBeforeAutoLock'),
            value: _autoLockDuration,
            items: _lockDurations,
            onChanged: (value) {
              setState(() => _autoLockDuration = value);
              _saveSetting('auto_lock_duration', value);
            },
          ),
        ],
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('dataEncryption'),
          subtitle: locale.translate('encryptLocalData'),
          value: _dataEncryption,
          onChanged: (value) {
            setState(() => _dataEncryption = value);
            _saveSetting('data_encryption', value);
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('privacy'),
      icon: Icons.privacy_tip_outlined,
      children: [
        _buildSwitchTile(
          title: locale.translate('analyticsTracking'),
          subtitle: locale.translate('helpImproveApp'),
          value: _analyticsTracking,
          onChanged: (value) {
            setState(() => _analyticsTracking = value);
            _saveSetting('analytics_tracking', value);
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('crashReporting'),
          subtitle: locale.translate('sendCrashReports'),
          value: _crashReporting,
          onChanged: (value) {
            setState(() => _crashReporting = value);
            _saveSetting('crash_reporting', value);
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('personalizedAds'),
          subtitle: locale.translate('showRelevantAds'),
          value: _personalizedAds,
          onChanged: (value) {
            setState(() => _personalizedAds = value);
            _saveSetting('personalized_ads', value);
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('locationTracking'),
          subtitle: locale.translate('shareLocationData'),
          value: _locationTracking,
          onChanged: (value) {
            setState(() => _locationTracking = value);
            _saveSetting('location_tracking', value);
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('dataManagement'),
      icon: Icons.storage_outlined,
      children: [
        _buildActionTile(
          title: locale.translate('downloadData'),
          subtitle: locale.translate('exportPersonalData'),
          icon: Icons.download_outlined,
          onTap: _downloadData,
        ),
        _buildDivider(),
        _buildActionTile(
          title: locale.translate('deleteAccount'),
          subtitle: locale.translate('permanentlyDeleteAccount'),
          icon: Icons.delete_forever_outlined,
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('quickActions'),
      icon: Icons.flash_on_outlined,
      children: [
        _buildActionTile(
          title: locale.translate('viewPrivacyPolicy'),
          subtitle: locale.translate('readOurPrivacyPolicy'),
          icon: Icons.policy_outlined,
          onTap: _viewPrivacyPolicy,
        ),
        _buildDivider(),
        _buildActionTile(
          title: locale.translate('securityTips'),
          subtitle: locale.translate('learnAboutSecurity'),
          icon: Icons.tips_and_updates_outlined,
          onTap: _viewSecurityTips,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(AppConstants.primaryTeal),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(AppConstants.primaryTeal),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']!),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? const Color(AppConstants.primaryTeal),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }

  void _downloadData() {
    _showSnackBar('Data export feature will be available soon');
  }

  void _viewPrivacyPolicy() {
    _showSnackBar('Privacy policy will be displayed here');
  }

  void _viewSecurityTips() {
    _showSnackBar('Security tips will be displayed here');
  }

  void _showDeleteAccountDialog() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              locale.translate('deleteAccount'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          locale.translate('deleteAccountWarning'),
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              locale.translate('cancel'),
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            child: Text(
              locale.translate('delete'),
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    _showSnackBar('Account deletion feature will be available soon');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(AppConstants.primaryTeal),
      ),
    );
  }
}