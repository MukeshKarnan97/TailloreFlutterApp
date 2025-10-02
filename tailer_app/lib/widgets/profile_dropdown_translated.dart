import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';

class ProfileDropdown extends StatefulWidget {
  final String? userAvatarUrl;
  final String? userName;
  final String? userEmail;
  final int notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onAboutTap;
  final VoidCallback? onLogoutTap;

  const ProfileDropdown({
    Key? key,
    this.userAvatarUrl,
    this.userName,
    this.userEmail,
    this.notificationCount = 0,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.onHelpTap,
    this.onAboutTap,
    this.onLogoutTap,
  }) : super(key: key);

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  bool _isDarkMode = false;
  final AuthService _authService = AuthService();
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black26,
          child: _buildProfileIcon(),
          itemBuilder: (BuildContext context) => [
            // User Profile Section
            _buildUserProfileHeader(),
            const PopupMenuDivider(height: 1),
            
            // Notifications
            _buildMenuItem(
              value: 'notifications',
              icon: Icons.notifications_outlined,
              title: locale.translate('notifications'),
              badge: widget.notificationCount > 0 ? widget.notificationCount.toString() : null,
              onTap: () => _handleNotifications(context, locale),
            ),
            
            // Settings
            _buildMenuItem(
              value: 'settings',
              icon: Icons.settings_outlined,
              title: locale.translate('settings'),
              onTap: () => _handleSettings(context),
            ),
            
            // Language Selection
            _buildMenuItem(
              value: 'language',
              icon: Icons.language_rounded,
              title: locale.translate('language'),
              trailing: Text(
                _getCurrentLanguageName(locale),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _handleLanguageSelection(context, locale),
            ),
            
            // Dark/Light Mode Toggle
            _buildToggleMenuItem(
              value: 'theme',
              icon: _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              title: _isDarkMode ? locale.translate('lightMode') : locale.translate('darkMode'),
              onTap: () => _toggleTheme(locale),
            ),
            
            // Help & Support
            _buildMenuItem(
              value: 'help',
              icon: Icons.help_outline,
              title: locale.translate('helpCenter'),
              onTap: () => _handleHelp(context, locale),
            ),
            
            // About
            _buildMenuItem(
              value: 'about',
              icon: Icons.info_outline,
              title: locale.translate('about'),
              onTap: () => _handleAbout(context, locale),
            ),
            
            const PopupMenuDivider(height: 1),
            
            // Logout
            _buildMenuItem(
              value: 'logout',
              icon: Icons.logout_outlined,
              title: locale.translate('logout'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _handleLogout(context, locale),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(AppConstants.primaryTeal),
            backgroundImage: widget.userAvatarUrl != null 
                ? NetworkImage(widget.userAvatarUrl!) 
                : null,
            child: widget.userAvatarUrl == null
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
          // Notification badge
          if (widget.notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  widget.notificationCount > 99 ? '99+' : widget.notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildUserProfileHeader() {
    return PopupMenuItem<String>(
      enabled: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(AppConstants.primaryTeal),
              backgroundImage: widget.userAvatarUrl != null 
                  ? NetworkImage(widget.userAvatarUrl!) 
                  : null,
              child: widget.userAvatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName ?? 'User Name',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.userEmail ?? 'user@example.com',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String title,
    String? badge,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildToggleMenuItem({
    required String value,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  Navigator.pop(context);
                  final locale = AppLocalizations.of(_localeProvider.languageCode);
                  _toggleTheme(locale);
                },
                activeColor: const Color(AppConstants.primaryTeal),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentLanguageName(AppLocalizations locale) {
    switch (_localeProvider.languageCode) {
      case 'ta':
        return locale.translate('tamil');
      case 'hi':
        return locale.translate('hindi');
      case 'en':
      default:
        return locale.translate('english');
    }
  }

  // Navigation and action handlers
  void _handleNotifications(BuildContext context, AppLocalizations locale) {
    if (widget.onNotificationsTap != null) {
      widget.onNotificationsTap!();
    } else {
      // Default notification action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${locale.translate('notifications')}: ${widget.notificationCount}'),
          backgroundColor: const Color(AppConstants.primaryTeal),
        ),
      );
    }
  }

  void _handleSettings(BuildContext context) {
    if (widget.onSettingsTap != null) {
      widget.onSettingsTap!();
    } else {
      // Navigate to settings screen
      context.goNamed(RouteNames.settings);
    }
  }

  void _handleLanguageSelection(BuildContext context, AppLocalizations locale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.language_rounded,
                color: const Color(AppConstants.primaryTeal),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                locale.translate('selectLanguage'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale.translate('languageSelectionSubtitle'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(
                context: context,
                locale: locale,
                languageCode: 'en',
                languageName: locale.translate('english'),
                nativeName: 'English',
                flag: '🇺🇸',
                isSelected: _localeProvider.languageCode == 'en',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context: context,
                locale: locale,
                languageCode: 'ta',
                languageName: locale.translate('tamil'),
                nativeName: 'தமிழ்',
                flag: '🇮🇳',
                isSelected: _localeProvider.languageCode == 'ta',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context: context,
                locale: locale,
                languageCode: 'hi',
                languageName: locale.translate('hindi'),
                nativeName: 'हिन्दी',
                flag: '🇮🇳',
                isSelected: _localeProvider.languageCode == 'hi',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                locale.translate('cancel'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLocalizations locale,
    required String languageCode,
    required String languageName,
    required String nativeName,
    required String flag,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await _localeProvider.setLanguage(languageCode);
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.translate('languageChanged')),
              backgroundColor: const Color(AppConstants.primaryTeal),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(AppConstants.primaryTeal)
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(AppConstants.primaryTeal).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(AppConstants.primaryTeal)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nativeName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: const Color(AppConstants.primaryTeal),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTheme(AppLocalizations locale) {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // TODO: Implement theme switching logic with provider/bloc
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isDarkMode ? locale.translate('darkMode') : locale.translate('lightMode')} ${locale.translate('enabled')}'),
        backgroundColor: const Color(AppConstants.primaryTeal),
      ),
    );
  }

  void _handleHelp(BuildContext context, AppLocalizations locale) {
    if (widget.onHelpTap != null) {
      widget.onHelpTap!();
    } else {
      // Show help dialog or navigate to help screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(locale.translate('helpCenter')),
          content: Text('Contact us at support@tailorapp.com\nPhone: +1 (555) 123-4567'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.translate('close')),
            ),
          ],
        ),
      );
    }
  }

  void _handleAbout(BuildContext context, AppLocalizations locale) {
    if (widget.onAboutTap != null) {
      widget.onAboutTap!();
    } else {
      // Show about dialog
      showAboutDialog(
        context: context,
        applicationName: 'Tailor App',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.content_cut, size: 32),
        children: [
          Text(locale.translate('comprehensiveTailorManagement')),
        ],
      );
    }
  }

  void _handleLogout(BuildContext context, AppLocalizations locale) {
    if (widget.onLogoutTap != null) {
      widget.onLogoutTap!();
    } else {
      // Show logout confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(locale.translate('logout')),
          content: Text(locale.translate('logoutConfirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authService.signOut();
                if (context.mounted) {
                  context.goNamed(RouteNames.signIn);
                }
              },
              child: Text(
                locale.translate('logout'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }
}