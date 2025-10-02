import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple language provider without external dependencies
/// Manages language selection and persistence using singleton pattern
class SimpleLocaleProvider extends ChangeNotifier {
  String _languageCode = 'en'; // Default language
  static const String _languageKey = 'selected_language';
  
  // Singleton pattern
  static final SimpleLocaleProvider _instance = SimpleLocaleProvider._internal();
  factory SimpleLocaleProvider() => _instance;
  SimpleLocaleProvider._internal() {
    _loadLanguage();
  }

  String get languageCode => _languageCode;
  
  String get languageName {
    switch (_languageCode) {
      case 'ta':
        return 'தமிழ்';
      case 'hi':
        return 'हिन्दी';
      case 'en':
      default:
        return 'English';
    }
  }

  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null && ['en', 'ta', 'hi'].contains(savedLanguage)) {
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
