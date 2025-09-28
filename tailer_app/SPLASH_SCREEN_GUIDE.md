# 🎬 Splash Screen System Documentation

## Overview

The Tailor App features a beautiful, animated splash screen system that provides:
- **Smooth animations** with fade-in, scale, and shimmer effects
- **App initialization** with progress tracking
- **Error handling** with retry functionality
- **Environment-specific configurations**
- **Performance optimizations**
- **Comprehensive logging integration**

## 📁 File Structure

```
lib/
├── features/
│   └── splash/
│       ├── animated_splash_screen.dart    # Main animated splash widget
│       └── splash_screen_manager.dart     # Initialization and navigation
└── features/
    └── home/
        └── home_screen.dart               # Demo home screen

flutter_native_splash.yaml                # Native splash configuration
.env.splash                               # Splash-specific configuration
```

## 🎨 Visual Features

### **Animated Elements:**
- **Logo Animation**: Fade-in and elastic scale effect
- **App Name**: Shimmer text animation
- **Background**: Animated gradient with pattern overlay  
- **Loading Dots**: Pulsing animation sequence
- **Progress Bar**: Smooth progress tracking
- **Version Info**: Fade-in corner display

### **Design Elements:**
```dart
// Gradient Colors (Light/Dark Mode)
Light Mode: [#667eea, #764ba2, #6B73FF]
Dark Mode:  [#1A1A2E, #16213E, #0F3460]

// Animations Timing
Logo Fade:     1500ms (Curves.easeIn)
Logo Scale:    1200ms (Curves.elasticOut)  
Shimmer:       2000ms (Repeating)
Total Duration: 3000ms (configurable)
```

## 🚀 Usage Examples

### **Basic Implementation:**
```dart
// In main.dart
MaterialApp(
  home: SplashScreenManager(
    mainAppBuilder: () => const HomeScreen(),
    splashDuration: Duration(seconds: 3),
  ),
)
```

### **Custom Configuration:**
```dart
SplashScreenManager(
  mainAppBuilder: () => const MyMainApp(),
  authScreenBuilder: () => const LoginScreen(), // Optional auth screen
  splashDuration: Duration(
    seconds: AppConfig.isDevelopment ? 2 : 3
  ),
)
```

### **Environment-Specific Durations:**
```dart
// From .env configuration
SPLASH_DURATION_DEV=2000     # 2 seconds for development
SPLASH_DURATION_PROD=3000    # 3 seconds for production

// Usage in code
Duration splashDuration = AppConfig.isDevelopment 
  ? Duration(milliseconds: AppConfig.splashDurationDev)
  : Duration(milliseconds: AppConfig.splashDurationProd);
```

## ⚙️ Configuration Options

### **Environment Variables (.env):**
```env
# Splash Timing
SPLASH_DURATION_DEV=2000              # Development duration (ms)
SPLASH_DURATION_PROD=3000             # Production duration (ms)

# Animation Timing  
SPLASH_FADE_DURATION=1500             # Logo fade duration (ms)
SPLASH_SCALE_DURATION=1200            # Logo scale duration (ms)
SPLASH_SHIMMER_DURATION=2000          # Shimmer duration (ms)

# Visual Features
SPLASH_PROGRESS_ENABLED=true          # Show progress bar
SPLASH_VERSION_INFO_ENABLED=true      # Show version info
SPLASH_TAGLINE_ENABLED=true           # Show tagline

# Error Handling
SPLASH_ERROR_RETRY_ENABLED=true       # Enable retry button
SPLASH_ERROR_DEBUG_INFO=true          # Show debug info (dev only)
```

### **Native Splash Configuration (flutter_native_splash.yaml):**
```yaml
flutter_native_splash:
  color: "#667eea"                     # Background color
  image: assets/images/splash_logo.jpg # Logo image
  
  android_12:
    image: assets/images/splash_logo.jpg
    icon_background_color: "#667eea"
    color: "#667eea"
  
  fullscreen: true                     # Full screen mode
  ios: true                           # Enable iOS splash
  web: false                          # Disable web splash
```

## 🔧 Initialization Sequence

### **App Startup Flow:**
```
1. Native Splash (flutter_native_splash)
   ↓
2. Custom Animated Splash (AnimatedSplashScreen)  
   ↓
3. App Initialization (SplashScreenManager)
   - Configuration loading
   - Database setup
   - Authentication check
   - Additional initialization
   ↓
4. Main App Navigation (HomeScreen/AuthScreen)
```

### **Initialization Tasks:**
```dart
// Performed during splash screen
✅ Device orientation setup
✅ Configuration validation  
✅ Database initialization
✅ Authentication state check
✅ Logger configuration
✅ Performance monitoring setup
```

## 🎭 Animation Details

### **Logo Animation Sequence:**
```dart
// 1. Fade In (300ms delay)
FadeTransition: 0.0 → 1.0 (1500ms, Curves.easeIn)

// 2. Scale Animation (500ms delay)  
ScaleTransition: 0.5 → 1.0 (1200ms, Curves.elasticOut)

// 3. Shimmer Effect (800ms delay)
ShaderMask: Repeating shimmer animation (2000ms)
```

### **Progress Animation:**
```dart
// Progress bar synchronized with initialization
LinearProgressIndicator: 0% → 100% (matches splash duration)

// Loading dots animation
3 dots with staggered pulsing effect (300ms intervals)
```

### **Background Pattern:**
```dart
// Animated diagonal lines and floating circles
CustomPainter: 
- Diagonal lines moving with animation value
- Floating circles with size variation
- Semi-transparent overlay (opacity: 0.05-0.1)
```

## 🛡️ Error Handling

### **Initialization Failure:**
```dart
// Error screen with retry functionality
- Red gradient background
- Error icon and message
- Retry button to restart initialization
- Debug info button (development only)
- Detailed error logging
```

### **Error Recovery:**
```dart
try {
  await initializeApp();
} catch (e, stackTrace) {
  Logger.error('SplashManager', 'Init failed', error: e, stackTrace: stackTrace);
  showErrorScreen(e.toString());
}
```

### **Development Debug Features:**
```dart
// Only in development builds
if (AppConfig.isDevelopment) {
  - Debug information dialog
  - Configuration viewer  
  - Error stack traces
  - Performance metrics
  - Shorter splash duration
}
```

## 📊 Performance Considerations

### **Optimizations:**
- **Lazy loading**: Only load required assets
- **Animation disposal**: Proper cleanup of controllers
- **Memory management**: Dispose resources on screen exit
- **Background processing**: Initialize app during animation

### **Performance Monitoring:**
```dart
// Logged performance metrics
✅ Animation duration tracking
✅ Initialization time measurement  
✅ Memory usage monitoring
✅ Frame rate optimization
✅ Asset loading time
```

## 🎨 Customization Examples

### **Custom Colors:**
```dart
// Light mode gradient
colors: [
  const Color(0xFF667eea), // Blue
  const Color(0xFF764ba2), // Purple  
  const Color(0xFF6B73FF), // Indigo
]

// Dark mode gradient
colors: [
  const Color(0xFF1A1A2E), // Dark blue
  const Color(0xFF16213E), // Navy
  const Color(0xFF0F3460), // Deep blue
]
```

### **Custom Animation Timing:**
```dart
// Faster animations for development
_fadeController = AnimationController(
  duration: Duration(milliseconds: AppConfig.splashFadeDuration),
  vsync: this,
);

// Custom curves
animation: CurvedAnimation(
  parent: controller,
  curve: Curves.elasticOut,  // Bouncy effect
)
```

### **Custom Loading Messages:**
```dart
// Dynamic loading messages
final loadingMessages = [
  'Initializing app...',
  'Setting up database...',
  'Loading configurations...',
  'Almost ready...',
];

// Rotate messages during loading
Timer.periodic(Duration(seconds: 1), (timer) {
  if (mounted) setState(() {
    currentMessage = loadingMessages[timer.tick % loadingMessages.length];
  });
});
```

## 🔧 Troubleshooting

### **Common Issues:**

#### **Logo Not Displaying:**
```dart
// Check asset path in pubspec.yaml
flutter:
  assets:
    - assets/images/splash_logo.jpg

// Verify image exists
❌ File not found: Use fallback logo
✅ File exists: Display image with proper fit
```

#### **Animation Performance:**
```dart
// Optimize for lower-end devices
if (Platform.isAndroid && lowEndDevice) {
  // Reduce animation complexity
  shimmerEnabled = false;
  backgroundPatternEnabled = false;
}
```

#### **Initialization Timeout:**
```dart
// Add timeout handling
Future.timeout(
  Duration(seconds: 10),
  onTimeout: () => throw TimeoutException('Initialization timeout'),
)
```

### **Debug Commands:**
```bash
# Regenerate native splash
dart run flutter_native_splash:create

# Check asset loading
flutter analyze
flutter test

# Performance profiling  
flutter run --profile
```

## 🚀 Advanced Features

### **Conditional Splash Screens:**
```dart
// Different splash for first launch
bool isFirstLaunch = await PreferencesService.isFirstLaunch();

SplashScreenManager(
  mainAppBuilder: isFirstLaunch 
    ? () => OnboardingScreen()
    : () => HomeScreen(),
  splashDuration: isFirstLaunch 
    ? Duration(seconds: 4)  // Longer for onboarding
    : Duration(seconds: 2), // Shorter for returning users
)
```

### **Progress Callbacks:**
```dart
SplashScreenManager(
  onProgress: (progress, message) {
    Logger.info('Splash', 'Progress: ${(progress * 100).toInt()}% - $message');
  },
  onComplete: () {
    Logger.info('Splash', 'App initialization completed');
  },
)
```

### **A/B Testing Support:**
```dart
// Different splash variants
final splashVariant = await RemoteConfig.getSplashVariant();

switch (splashVariant) {
  case 'minimal':
    return MinimalSplashScreen();
  case 'animated': 
    return AnimatedSplashScreen();
  case 'video':
    return VideoSplashScreen();
}
```

This splash screen system provides a professional, polished experience for your Tailor App with comprehensive customization options and robust error handling! 🎯