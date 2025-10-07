import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { dark, system }

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> with NavigationMixin {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString('theme_mode') ?? 'system';
      
      setState(() {
        // If light theme was previously selected, default to dark
        if (themeString == 'light') {
          _selectedTheme = ThemeMode.dark;
        } else {
          _selectedTheme = ThemeMode.values.firstWhere(
            (theme) => theme.name == themeString,
            orElse: () => ThemeMode.system,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedTheme = ThemeMode.system;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', theme.name);
      
      setState(() {
        _selectedTheme = theme;
      });

      final locale = AppLocalizations.of(_localeProvider.languageCode);
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('themeChanged'),
          customMessage: locale.translate('themeChangedSuccessfully'),
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      final locale = AppLocalizations.of(_localeProvider.languageCode);
      
      if (mounted) {
        showNavigationMessage(
          context,
          locale.translate('changeFailed'),
          customMessage: locale.translate('themeChangeFailed'),
          backgroundColor: Colors.red,
        );
      }
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
              locale.translate('theme'),
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
                        _buildThemeHeader(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildThemeOptions(),
                        const SizedBox(height: AppConstants.spacingL),
                        _buildThemePreview(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildThemeHeader() {
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
          // Theme Icon
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
              Icons.palette_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('chooseAppearance'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('lightDarkSystemDefault'),
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

  Widget _buildThemeOptions() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
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
        children: [
          _buildThemeOption(
            theme: ThemeMode.dark,
            title: locale.translate('darkTheme'),
            subtitle: locale.translate('darkThemeDescription'),
            icon: Icons.dark_mode_outlined,
            iconColor: Colors.indigo,
          ),
          _buildDivider(),
          _buildThemeOption(
            theme: ThemeMode.system,
            title: locale.translate('systemTheme'),
            subtitle: locale.translate('systemThemeDescription'),
            icon: Icons.settings_outlined,
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required ThemeMode theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _saveTheme(theme),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<ThemeMode>(
                value: theme,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  if (value != null) {
                    _saveTheme(value);
                  }
                },
                activeColor: const Color(AppConstants.primaryTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildThemePreview() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    
    return Container(
      padding: const EdgeInsets.all(20),
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
            locale.translate('themePreview'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPreviewBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryTeal),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apps,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate('sampleTitle'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getPreviewTextColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locale.translate('sampleSubtitle'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _getPreviewTextColor().withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${locale.translate('currentlySelected')}: ${_getThemeName()}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPreviewBackgroundColor() {
    switch (_selectedTheme) {
      case ThemeMode.dark:
        return Colors.grey[800]!;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.white;
    }
  }

  Color _getPreviewTextColor() {
    switch (_selectedTheme) {
      case ThemeMode.dark:
        return Colors.white;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark
            ? Colors.white
            : Colors.black87;
    }
  }

  String _getThemeName() {
    final locale = AppLocalizations.of(_localeProvider.languageCode);
    switch (_selectedTheme) {
      case ThemeMode.dark:
        return locale.translate('darkTheme');
      case ThemeMode.system:
        return locale.translate('systemTheme');
    }
  }
}