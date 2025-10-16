import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  
  bool _isLoading = true;
  bool _pushNotifications = true;
  bool _orderUpdates = true;
  bool _paymentReminders = true;
  bool _marketingMessages = false;
  bool _emailNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _orderUpdates = prefs.getBool('order_updates') ?? true;
        _paymentReminders = prefs.getBool('payment_reminders') ?? true;
        _marketingMessages = prefs.getBool('marketing_messages') ?? false;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
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
              locale.translate('notifications'),
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
                        _buildNotificationHeader(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildPushNotificationSection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildNotificationTypesSection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildSoundVibrationSection(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildEmailSection(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNotificationHeader() {
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
                  Colors.blue,
                  Colors.blue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('manageNotificationPreferences'),
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

  Widget _buildPushNotificationSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('pushNotifications'),
      icon: Icons.smartphone_outlined,
      children: [
        _buildSwitchTile(
          title: locale.translate('enablePushNotifications'),
          subtitle: locale.translate('receiveNotificationsOnDevice'),
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
            _saveSetting('push_notifications', value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationTypesSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('notificationTypes'),
      icon: Icons.category_outlined,
      children: [
        _buildSwitchTile(
          title: locale.translate('orderUpdates'),
          subtitle: locale.translate('orderStatusChanges'),
          value: _orderUpdates,
          onChanged: _pushNotifications ? (value) {
            setState(() => _orderUpdates = value);
            _saveSetting('order_updates', value);
          } : null,
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('paymentReminders'),
          subtitle: locale.translate('paymentDueNotifications'),
          value: _paymentReminders,
          onChanged: _pushNotifications ? (value) {
            setState(() => _paymentReminders = value);
            _saveSetting('payment_reminders', value);
          } : null,
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('marketingMessages'),
          subtitle: locale.translate('promotionalContent'),
          value: _marketingMessages,
          onChanged: _pushNotifications ? (value) {
            setState(() => _marketingMessages = value);
            _saveSetting('marketing_messages', value);
          } : null,
        ),
      ],
    );
  }

  Widget _buildSoundVibrationSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('soundVibration'),
      icon: Icons.volume_up_outlined,
      children: [
        _buildSwitchTile(
          title: locale.translate('sound'),
          subtitle: locale.translate('playNotificationSounds'),
          value: _soundEnabled,
          onChanged: _pushNotifications ? (value) {
            setState(() => _soundEnabled = value);
            _saveSetting('sound_enabled', value);
          } : null,
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: locale.translate('vibration'),
          subtitle: locale.translate('vibrateOnNotifications'),
          value: _vibrationEnabled,
          onChanged: _pushNotifications ? (value) {
            setState(() => _vibrationEnabled = value);
            _saveSetting('vibration_enabled', value);
          } : null,
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return _buildSection(
      title: locale.translate('emailNotifications'),
      icon: Icons.email_outlined,
      children: [
        _buildSwitchTile(
          title: locale.translate('emailUpdates'),
          subtitle: locale.translate('receiveEmailUpdates'),
          value: _emailNotifications,
          onChanged: (value) {
            setState(() => _emailNotifications = value);
            _saveSetting('email_notifications', value);
          },
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
    required Function(bool)? onChanged,
  }) {
    final isEnabled = onChanged != null;
    
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
                    color: isEnabled ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(AppConstants.primaryTeal),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
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
}