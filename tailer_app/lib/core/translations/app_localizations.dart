/// Simple dictionary-based language support without external libraries
/// Supports English and Tamil languages
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  // Translation dictionaries
  static final Map<String, Map<String, String>> _translations = {
    // English translations
    'en': {
      // Navigation
      'dashboard': 'Dashboard',
      'customers': 'Customers',
      'orders': 'Orders',
      'settings': 'Settings',
      'measurements': 'Measurements',
      
      // Auth
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'logout': 'Logout',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'rememberMe': 'Remember Me',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      
      // Customer Management
      'addCustomer': 'Add Customer',
      'editCustomer': 'Edit Customer',
      'viewCustomers': 'View Customers',
      'customerDetails': 'Customer Details',
      'customerName': 'Customer Name',
      'phoneNumber': 'Phone Number',
      'address': 'Address',
      'searchCustomers': 'Search Customers',
      
      // Measurements
      'addMeasurement': 'Add Measurement',
      'editMeasurement': 'Edit Measurement',
      'measurementList': 'Measurement List',
      'measurementCategory': 'Measurement Category',
      'selectDressType': 'Select Dress Type',
      'shirt': 'Shirt',
      'pant': 'Pant',
      'blouse': 'Blouse',
      'churidar': 'Churidar',
      
      // Common Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'view': 'View',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'submit': 'Submit',
      'continue': 'Continue',
      'back': 'Back',
      'next': 'Next',
      
      // Messages
      'welcomeBack': 'Welcome Back!',
      'pleaseSignIn': 'Please sign in to continue',
      'success': 'Success',
      'error': 'Error',
      'loading': 'Loading...',
      'noDataFound': 'No data found',
      'confirmDelete': 'Are you sure you want to delete?',
      
      // Profile & Settings
      'profile': 'Profile',
      'myProfile': 'My Profile',
      'editProfile': 'Edit Profile',
      'changePassword': 'Change Password',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'theme': 'Theme',
      'notifications': 'Notifications',
      'help': 'Help',
      'about': 'About',
      'privacyPolicy': 'Privacy Policy',
      'termsConditions': 'Terms & Conditions',
      
      // Dashboard
      'totalCustomers': 'Total Customers',
      'activeOrders': 'Active Orders',
      'completedOrders': 'Completed Orders',
      'pendingPayments': 'Pending Payments',
      'recentActivity': 'Recent Activity',
      'quickActions': 'Quick Actions',
      
      // Demo Page
      'languageDemo': 'Language Demo',
      'demoDescription': 'Change language to see all texts update automatically',
      'currentLanguage': 'Current Language',
      'sampleTexts': 'Sample Texts',
      'inputFieldsNote': 'Note: Input fields remain unchanged',
      'navigationItems': 'Navigation Items',
      'authScreens': 'Authentication Screens',
      'customerManagement': 'Customer Management',
      'commonActions': 'Common Actions',
    },
    
    // Tamil translations
    'ta': {
      // Navigation
      'dashboard': 'டாஷ்போர்டு',
      'customers': 'வாடிக்கையாளர்கள்',
      'orders': 'ஆர்டர்கள்',
      'settings': 'அமைப்புகள்',
      'measurements': 'அளவுகள்',
      
      // Auth
      'signIn': 'உள்நுழைக',
      'signUp': 'பதிவு செய்க',
      'logout': 'வெளியேறு',
      'forgotPassword': 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?',
      'resetPassword': 'கடவுச்சொல்லை மீட்டமைக்கவும்',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'confirmPassword': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
      'rememberMe': 'என்னை நினைவில் கொள்',
      'dontHaveAccount': 'கணக்கு இல்லையா?',
      'alreadyHaveAccount': 'ஏற்கனவே கணக்கு உள்ளதா?',
      
      // Customer Management
      'addCustomer': 'வாடிக்கையாளரைச் சேர்க்கவும்',
      'editCustomer': 'வாடிக்கையாளரைத் திருத்தவும்',
      'viewCustomers': 'வாடிக்கையாளர்களைப் பார்க்கவும்',
      'customerDetails': 'வாடிக்கையாளர் விவரங்கள்',
      'customerName': 'வாடிக்கையாளர் பெயர்',
      'phoneNumber': 'தொலைபேசி எண்',
      'address': 'முகவரி',
      'searchCustomers': 'வாடிக்கையாளர்களைத் தேடுங்கள்',
      
      // Measurements
      'addMeasurement': 'அளவை சேர்க்கவும்',
      'editMeasurement': 'அளவை திருத்தவும்',
      'measurementList': 'அளவு பட்டியல்',
      'measurementCategory': 'அளவு வகை',
      'selectDressType': 'ஆடை வகையைத் தேர்ந்தெடுக்கவும்',
      'shirt': 'சட்டை',
      'pant': 'பேண்ட்',
      'blouse': 'பிளவுஸ்',
      'churidar': 'சுரிதார்',
      
      // Common Actions
      'save': 'சேமிக்கவும்',
      'cancel': 'ரத்து செய்',
      'delete': 'நீக்கு',
      'edit': 'திருத்து',
      'view': 'பார்க்கவும்',
      'add': 'சேர்க்கவும்',
      'search': 'தேடு',
      'filter': 'வடிகட்டு',
      'submit': 'சமர்ப்பிக்கவும்',
      'continue': 'தொடரவும்',
      'back': 'பின்செல்',
      'next': 'அடுத்து',
      
      // Messages
      'welcomeBack': 'மீண்டும் வரவேற்கிறோம்!',
      'pleaseSignIn': 'தொடர உள்நுழைக',
      'success': 'வெற்றி',
      'error': 'பிழை',
      'loading': 'ஏற்றுகிறது...',
      'noDataFound': 'தரவு கிடைக்கவில்லை',
      'confirmDelete': 'நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
      
      // Profile & Settings
      'profile': 'சுயவிவரம்',
      'myProfile': 'என் சுயவிவரம்',
      'editProfile': 'சுயவிவரத்தைத் திருத்தவும்',
      'changePassword': 'கடவுச்சொல்லை மாற்றவும்',
      'language': 'மொழி',
      'selectLanguage': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'theme': 'தீம்',
      'notifications': 'அறிவிப்புகள்',
      'help': 'உதவி',
      'about': 'பற்றி',
      'privacyPolicy': 'தனியுரிமைக் கொள்கை',
      'termsConditions': 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
      
      // Dashboard
      'totalCustomers': 'மொத்த வாடிக்கையாளர்கள்',
      'activeOrders': 'செயலில் உள்ள ஆர்டர்கள்',
      'completedOrders': 'முடிக்கப்பட்ட ஆர்டர்கள்',
      'pendingPayments': 'நிலுவையில் உள்ள கொடுப்பனவுகள்',
      'recentActivity': 'சமீபத்திய செயல்பாடு',
      'quickActions': 'விரைவு செயல்கள்',
      
      // Demo Page
      'languageDemo': 'மொழி டெமோ',
      'demoDescription': 'அனைத்து உரைகளும் தானாகவே புதுப்பிக்கப்படுவதைப் பார்க்க மொழியை மாற்றவும்',
      'currentLanguage': 'தற்போதைய மொழி',
      'sampleTexts': 'மாதிரி உரைகள்',
      'inputFieldsNote': 'குறிப்பு: உள்ளீட்டு புலங்கள் மாறாது',
      'navigationItems': 'வழிசெலுத்தல் உருப்படிகள்',
      'authScreens': 'அங்கீகார திரைகள்',
      'customerManagement': 'வாடிக்கையாளர் மேலாண்மை',
      'commonActions': 'பொதுவான செயல்கள்',
    },
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

  // Get available languages
  static List<LanguageOption> get availableLanguages => [
    const LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    const LanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  ];
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
