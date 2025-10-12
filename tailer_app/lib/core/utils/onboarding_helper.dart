import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// OnboardingHelper - Utility for managing onboarding flow completion
class OnboardingHelper {
  static const String _className = 'OnboardingHelper';
  static const String _getStartedKey = 'get_started_completed';
  static const String _userAgreementKey = 'user_agreement_accepted';
  
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

  /// Checks if User Agreement was accepted
  static Future<bool> isUserAgreementAccepted() async {
    try {
      Logger.info(_className, 'Checking User Agreement acceptance status');
      
      final prefs = await SharedPreferences.getInstance();
      final isAccepted = prefs.getBool(_userAgreementKey) ?? false;
      
      Logger.debug(_className, 'User Agreement accepted: $isAccepted');
      
      return isAccepted;
    } catch (e) {
      Logger.error(_className, 'Failed to check User Agreement status: $e');
      return false;
    }
  }

  /// Sets User Agreement as accepted
  static Future<bool> setUserAgreementAccepted() async {
    try {
      Logger.info(_className, 'Setting User Agreement as accepted');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userAgreementKey, true);
      
      Logger.debug(_className, 'User Agreement acceptance saved successfully');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to save User Agreement acceptance: $e');
      return false;
    }
  }

  /// Clears User Agreement acceptance (for testing)
  static Future<bool> clearUserAgreementAcceptance() async {
    try {
      Logger.info(_className, 'Clearing User Agreement acceptance');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userAgreementKey);
      
      Logger.debug(_className, 'User Agreement acceptance cleared');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to clear User Agreement acceptance: $e');
      return false;
    }
  }

  /// Checks if the complete onboarding flow is finished
  /// (Get Started, User Agreement, and Privacy Policy completed)
  static Future<bool> isOnboardingComplete() async {
    try {
      Logger.info(_className, 'Checking complete onboarding status');
      
      final getStartedCompleted = await isGetStartedCompleted();
      final userAgreementAccepted = await isUserAgreementAccepted();
      
      // Import PrivacyPolicyHelper to check privacy policy status
      final prefs = await SharedPreferences.getInstance();
      final privacyPolicyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;
      
      final isComplete = getStartedCompleted && userAgreementAccepted && privacyPolicyAccepted;
      
      Logger.debug(_className, 'Onboarding complete: $isComplete (GetStarted: $getStartedCompleted, Agreement: $userAgreementAccepted, Privacy: $privacyPolicyAccepted)');
      
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
      await prefs.remove(_userAgreementKey);
      await prefs.remove('privacy_policy_accepted');
      
      Logger.debug(_className, 'All onboarding progress cleared');
      return true;
    } catch (e) {
      Logger.error(_className, 'Failed to reset onboarding: $e');
      return false;
    }
  }
}