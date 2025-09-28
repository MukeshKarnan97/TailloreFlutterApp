import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// PrivacyPolicyHelper - Utility for managing privacy policy acceptance
class PrivacyPolicyHelper {
  static const String _className = 'PrivacyPolicyHelper';
  static const String _prefsKey = 'privacy_policy_accepted';

  /// Checks if privacy policy was already accepted
  static Future<bool> isAccepted() async {
    try {
      Logger.info(_className, 'Checking privacy policy acceptance status');
      
      final prefs = await SharedPreferences.getInstance();
      final isAccepted = prefs.getBool(_prefsKey) ?? false;
      
      Logger.debug(_className, 'Privacy policy accepted: $isAccepted');
      
      return isAccepted;
    } catch (e) {
      Logger.error(_className, 'Failed to check privacy policy status: $e');
      return false;
    }
  }

  /// Accepts the privacy policy and stores the acceptance
  static Future<bool> setAccepted() async {
    try {
      Logger.info(_className, 'Setting privacy policy as accepted');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
      
      Logger.debug(_className, 'Privacy policy acceptance stored successfully');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to store privacy policy acceptance: $e');
      return false;
    }
  }

  /// Clears privacy policy acceptance (for testing)
  static Future<bool> clearAcceptance() async {
    try {
      Logger.info(_className, 'Clearing privacy policy acceptance');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      
      Logger.debug(_className, 'Privacy policy acceptance cleared');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to clear privacy policy acceptance: $e');
      return false;
    }
  }
}