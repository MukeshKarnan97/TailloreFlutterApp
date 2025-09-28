/// App-wide constants for the Tailor App
class AppConstants {
  // Spacing constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 40.0;
  
  // Authentication constants
  static const int minPasswordLength = 8;
  static const Duration authTimeout = Duration(seconds: 30);
  static const Duration loadingDelay = Duration(seconds: 2); // For demo purposes
  
  // Validation patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)';
  
  // Colors
  static const int primaryOrange = 0xFFF56B3F;
  static const int primaryTeal = 0xFF21899C;
  static const int greyText = 0xFF969AA8;
  static const int borderGrey = 0xFFD0D0D0;
  
  // Border radius
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 4.0;
  
  // Error messages
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordLengthError = 'Password must be at least 8 characters';
  static const String passwordComplexityError = 'Include uppercase, lowercase & number';
  
  // Success messages
  static const String signInSuccessMessage = 'Sign in successful!';
  static const String forgotPasswordMessage = 'Forgot password feature coming soon!';
}