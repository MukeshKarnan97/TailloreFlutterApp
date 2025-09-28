import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// OnboardingHelper - Utility for managing onboarding flow completion
class OnboardingHelper {
  static const String _className = 'OnboardingHelper';
  static const String _getStartedKey = 'get_started_completed';
  
  /// Checks if Get Started screen was completed
  static Future<bool> isGetStartedCompleted() async {
    try {
      Logger.info(_className, 'Checking Get Started completion status');
      
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_getStartedKey) ?? false;
      
      Logger.debug(_className, 'Get Started completed: $isCompleted');
      
      return isCompleted;
    } catch (e) {
      Logger.error(_className, 'Failed to check Get Started status: $e');
      return false;
    }
  }

  /// Sets Get Started screen as completed
  static Future<bool> setGetStartedCompleted() async {
    try {
      Logger.info(_className, 'Setting Get Started as completed');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_getStartedKey, true);
      
      Logger.debug(_className, 'Get Started completion saved successfully');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to save Get Started completion: $e');
      return false;
    }
  }

  /// Clears Get Started completion (for testing)
  static Future<bool> clearGetStartedCompletion() async {
    try {
      Logger.info(_className, 'Clearing Get Started completion');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getStartedKey);
      
      Logger.debug(_className, 'Get Started completion cleared');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to clear Get Started completion: $e');
      return false;
    }
  }

  /// Checks if the complete onboarding flow is finished
  /// (Both Get Started and Privacy Policy completed)
  static Future<bool> isOnboardingComplete() async {
    try {
      Logger.info(_className, 'Checking complete onboarding status');
      
      final getStartedCompleted = await isGetStartedCompleted();
      
      // Import PrivacyPolicyHelper to check privacy policy status
      final prefs = await SharedPreferences.getInstance();
      final privacyPolicyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;
      
      final isComplete = getStartedCompleted && privacyPolicyAccepted;
      
      Logger.debug(_className, 'Onboarding complete: $isComplete (GetStarted: $getStartedCompleted, Privacy: $privacyPolicyAccepted)');
      
      return isComplete;
    } catch (e) {
      Logger.error(_className, 'Failed to check onboarding completion: $e');
      return false;
    }
  }

  /// Resets all onboarding progress (for testing)
  static Future<bool> resetOnboarding() async {
    try {
      Logger.info(_className, 'Resetting all onboarding progress');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getStartedKey);
      await prefs.remove('privacy_policy_accepted');
      
      Logger.debug(_className, 'All onboarding progress cleared');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to reset onboarding: $e');
      return false;
    }
  }
}