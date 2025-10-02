import 'package:flutter/material.dart';
import 'package:tailer_app/core/providers/simple_locale_provider.dart';
import 'package:tailer_app/core/translations/app_localizations.dart';

/// Demo screen showing how language switching works with dictionary approach  
class SimpleLanguageDemoScreen extends StatefulWidget {
  const SimpleLanguageDemoScreen({Key? key}) : super(key: key);

  @override
  State<SimpleLanguageDemoScreen> createState() => _SimpleLanguageDemoScreenState();
}

class _SimpleLanguageDemoScreenState extends State<SimpleLanguageDemoScreen> {
  final SimpleLocaleProvider _localeProvider = SimpleLocaleProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeProvider,
      builder: (context, child) {
        final locale = AppLocalizations.of(_localeProvider.languageCode);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(locale.t('languageDemo')),
            backgroundColor: const Color(0xFFFF7248),
            actions: [
              IconButton(
                icon: const Icon(Icons.translate),
                onPressed: () => _localeProvider.toggleLanguage(),
                tooltip: locale.t('selectLanguage'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguageSelector(locale),
                const SizedBox(height: 24),
                _buildDescriptionCard(locale),
                const SizedBox(height: 24),
                _buildSection(locale.t('navigationItems'), [
                  locale.t('dashboard'),
                  locale.t('customers'),
                  locale.t('orders'),
                  locale.t('measurements'),
                  locale.t('settings'),
                ], Icons.navigation),
                const SizedBox(height: 16),
                _buildSection(locale.t('authScreens'), [
                  locale.t('signIn'),
                  locale.t('signUp'),
                  locale.t('forgotPassword'),
                  locale.t('logout'),
                ], Icons.lock_outline),
                const SizedBox(height: 16),
                _buildSection(locale.t('customerManagement'), [
                  locale.t('addCustomer'),
                  locale.t('editCustomer'),
                  locale.t('viewCustomers'),
                  locale.t('customerDetails'),
                ], Icons.people_outline),
                const SizedBox(height: 16),
                _buildInputFieldExample(locale),
                const SizedBox(height: 24),
                _buildBottomNavPreview(locale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(AppLocalizations locale) {
    return Card(
      elevation: 4,
      color: const Color(0xFFFF7248),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.t('selectLanguage'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageButton('English', 'en', _localeProvider.languageCode == 'en'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageButton('தமிழ்', 'ta', _localeProvider.languageCode == 'ta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String code, bool isSelected) {
    return InkWell(
      onTap: () => _localeProvider.setLanguage(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFF7248) : Colors.white,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle, color: Color(0xFFFF7248), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF7248)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.t('demoDescription'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${locale.t('currentLanguage')}: ${_localeProvider.languageName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.t('inputFieldsNote'),
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF7248)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Chip(
                label: Text(item),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: Colors.grey.shade300),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFieldExample(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: Color(0xFFFF7248)),
                const SizedBox(width: 8),
                Text(
                  locale.t('inputFieldsNote'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Customer Name (unchanged)',
                hintText: 'Enter customer name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number (unchanged)',
                hintText: 'Enter phone number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavPreview(AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bottom Navigation Preview:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dashboard, locale.t('dashboard'), true),
                  _buildNavItem(Icons.people, locale.t('customers'), false),
                  _buildNavItem(Icons.shopping_bag, locale.t('orders'), false),
                  _buildNavItem(Icons.settings, locale.t('settings'), false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF7248) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFFFF7248) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localeProvider.dispose();
    super.dispose();
  }
}
