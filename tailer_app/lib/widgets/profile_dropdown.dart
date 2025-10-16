import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/app_colors.dart';
import 'package:tailer_app/data/services/auth_service.dart';
import 'package:tailer_app/routes/app_routes.dart';
import 'package:tailer_app/routes/route_names.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';

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
    super.key,
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
  });

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
          color: AppColors.surface,
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: _isDarkMode ? Colors.black87 : Colors.black26,
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
              onTap: () => _handleNotifications(context),
            ),
            
            // Language Selection
            _buildMenuItem(
              value: 'language',
              icon: Icons.language_rounded,
              title: locale.translate('language'),
              trailing: Text(
                _getCurrentLanguageName(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _showLanguageSelection(context),
            ),
            
            // Settings
            _buildMenuItem(
              value: 'settings',
              icon: Icons.settings_outlined,
              title: locale.translate('settings'),
              onTap: () => _handleSettings(context),
            ),
            
            // Dark/Light Mode Toggle
            _buildToggleMenuItem(
              value: 'theme',
              icon: _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              title: _isDarkMode ? locale.translate('lightMode') : locale.translate('darkMode'),
              onTap: () => _toggleTheme(),
            ),
            
            // Help & Support
            _buildMenuItem(
              value: 'help',
              icon: Icons.help_outline,
              title: locale.translate('helpCenter'),
              onTap: () => _handleHelp(context),
            ),
            
            // About
            _buildMenuItem(
              value: 'about',
              icon: Icons.info_outline,
              title: locale.translate('about'),
              onTap: () => _handleAbout(context),
            ),
            
            
            const PopupMenuDivider(height: 1),
            
            // Logout
            _buildMenuItem(
              value: 'logout',
              icon: Icons.logout_outlined,
              title: locale.translate('logout'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _handleLogout(context),
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
            backgroundImage: widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty
                ? (widget.userAvatarUrl!.startsWith('http') 
                    ? NetworkImage(widget.userAvatarUrl!)
                    : FileImage(File(widget.userAvatarUrl!))) as ImageProvider
                : null,
            child: widget.userAvatarUrl == null || widget.userAvatarUrl!.isEmpty
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
              backgroundColor: AppColors.primary,
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
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.userEmail ?? 'user@example.com',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                color: iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
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
                  _toggleTheme();
                },
                activeThumbColor: const Color(AppConstants.primaryTeal),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation and action handlers
  void _handleNotifications(BuildContext context) {
    if (widget.onNotificationsTap != null) {
      widget.onNotificationsTap!();
    } else {
      // Default notification action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have ${widget.notificationCount} notifications'),
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

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Update AppColors theme globally
      AppColors.setDarkMode(_isDarkMode);
    });
    
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    // Show confirmation snackbar with theme colors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              '${_isDarkMode ? locale.translate('darkMode') : locale.translate('lightMode')} ${locale.translate('enabled')}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Force rebuild of the entire app (you might need to use a state management solution)
    // For now, this will update the dropdown menu immediately
  }

  void _handleHelp(BuildContext context) {
    if (widget.onHelpTap != null) {
      widget.onHelpTap!();
    } else {
      final locale = AppLocalizations.of(_localeProvider.languageCode);
      // Show help dialog or navigate to help screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(locale.translate('helpCenter')),
          content: const Text('Contact us at support@tailorapp.com\nPhone: +1 (555) 123-4567'),
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

  void _handleAbout(BuildContext context) {
    if (widget.onAboutTap != null) {
      widget.onAboutTap!();
    } else {
      final locale = AppLocalizations.of(_localeProvider.languageCode);
      // Show about dialog
      showAboutDialog(
        context: context,
        applicationName: 'Tailor App',
        applicationVersion: '1.0.0',
        applicationIcon: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.content_cut, size: 32);
            },
          ),
        ),
        children: [
          Text(locale.translate('comprehensiveTailorManagement')),
        ],
      );
    }
  }

  void _handleLogout(BuildContext context) {
    if (widget.onLogoutTap != null) {
      widget.onLogoutTap!();
    } else {
      final locale = AppLocalizations.of(_localeProvider.languageCode);
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

  // Language navigation methods
  String _getCurrentLanguageName() {
    switch (_localeProvider.languageCode) {
      case 'ta':
        return 'தமிழ்';
      case 'hi':
        return 'हिन्दी';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageSelection(BuildContext context) {
    // Navigate to the existing language selection screen
    context.pushNamed(RouteNames.languageSelection);
  }
}