import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple language provider without external dependencies
/// Manages language selection and persistence
class SimpleLocaleProvider extends ChangeNotifier {
  String _languageCode = 'en'; // Default language
  static const String _languageKey = 'selected_language';

  String get languageCode => _languageCode;
  
  String get languageName {
    switch (_languageCode) {
      case 'ta':
        return 'தமிழ்';
      case 'en':
      default:
        return 'English';
    }
  }

  SimpleLocaleProvider() {
    _loadLanguage();
  }

  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null && (savedLanguage == 'en' || savedLanguage == 'ta')) {
        _languageCode = savedLanguage;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  // Change language and save to SharedPreferences
  Future<void> setLanguage(String languageCode) async {
    if (_languageCode == languageCode) return;
    
    _languageCode = languageCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      debugPrint('Language changed to: $languageCode');
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  // Toggle between English and Tamil
  Future<void> toggleLanguage() async {
    final newLanguage = _languageCode == 'en' ? 'ta' : 'en';
    await setLanguage(newLanguage);
  }
}
