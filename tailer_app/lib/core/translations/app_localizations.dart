import 'locales/en_translations.dart';
import 'locales/ta_translations.dart';
import 'locales/hi_translations.dart';

/// Simple dictionary-based language support without external libraries
/// Supports English, Tamil, and Hindi languages
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  // Translation dictionaries - now imported from separate files
  static final Map<String, Map<String, String>> _translations = {
    'en': enTranslations,
    'ta': taTranslations,
    'hi': hiTranslations,
  };

  // Get translation for a key
  String translate(String key) {
    return _translations[languageCode]?[key] ?? key;
  }

  // Shorthand method
  String t(String key) => translate(key);

  // Helper method to get localization from context
  static AppLocalizations of(String languageCode) {
    return AppLocalizations(languageCode);
  }

  // Get available languages with full details
  static List<LanguageOption> get availableLanguages => [
    const LanguageOption(
      code: 'en', 
      name: 'English', 
      nativeName: 'English',
      flag: '🇺🇸',
      isoCode: 'EN',
    ),
    const LanguageOption(
      code: 'ta', 
      name: 'Tamil', 
      nativeName: 'தமிழ்',
      flag: '🇮🇳',
      isoCode: 'TA',
    ),
    const LanguageOption(
      code: 'hi', 
      name: 'Hindi', 
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      isoCode: 'HI',
    ),
  ];

  // Get supported language codes
  static List<String> get supportedLanguages => 
      availableLanguages.map((lang) => lang.code).toList();

  // Check if language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String isoCode;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isoCode,
  });
}
