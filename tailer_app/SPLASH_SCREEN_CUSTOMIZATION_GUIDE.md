# 🎨 Splash Screen Customization Guide

## Overview

Your app has **TWO splash screens**:

1. **Native Splash Screen** (Flutter icon) - Shows immediately when app is clicked
2. **Animated Splash Screen** (Custom design) - Shows after native splash

---

## 📱 1. NATIVE SPLASH SCREEN (First Screen)

### Current Status
- ❌ Currently showing: `assets/images/splash_logo.jpg`
- ⚙️ Configuration file: `flutter_native_splash.yaml`
- 🎨 Background color: Purple gradient (`#667eea`)

### Where to Add Your Icon

#### Option A: Use PNG/JPG Image (Recommended for Photos)
1. **Create your splash icon image:**
   - Size: 1024x1024 pixels (will be auto-resized)
   - Format: PNG (with transparency) or JPG
   - Name: `splash_icon.png` or `splash_logo.png`

2. **Save it here:**
   ```
   assets/images/splash_icon.png
   ```

3. **Update `flutter_native_splash.yaml`:**
   ```yaml
   image: assets/images/splash_icon.png
   
   android_12:
     image: assets/images/splash_icon.png
   ```

#### Option B: Use App Icon (Simpler)
Use your existing app icon:
```yaml
image: assets/icon/app_icon.png

android_12:
  image: assets/icon/app_icon.png
```

### Color Customization

#### Light Theme Colors (Professional Teal)
```yaml
flutter_native_splash:
  color: "#0D7377"  # Deep Teal (matches your app theme)
  
  android_12:
    icon_background_color: "#0D7377"
    color: "#0D7377"
```

#### Dark Theme Colors
```yaml
flutter_native_splash:
  color: "#0F1419"  # Dark background
  
  android_12:
    icon_background_color: "#14FFEC"  # Bright Teal
    color: "#0F1419"
```

#### Custom Gradient Effect (Requires image background)
Create a gradient image (1080x1920) and use:
```yaml
color: "#FFFFFF"  # White
image: assets/images/splash_background.png
```

---

## 🎭 2. ANIMATED SPLASH SCREEN (Second Screen)

### Current Status
- ✅ Located: `lib/features/splash/animated_splash_screen.dart`
- 🎨 Design: Purple gradient with logo animation
- ⏱️ Duration: 3 seconds
- 🖼️ Logo: `assets/images/splash_logo.jpg`

### Customization Options

#### Change Logo Image
**Current:** `assets/images/splash_logo.jpg`

**To change:**
1. Add your logo to `assets/images/`
2. Update line 282 in `animated_splash_screen.dart`:
   ```dart
   child: Image.asset(
     'assets/images/your_logo.png',  // Change this
     fit: BoxFit.cover,
   ),
   ```

#### Change Colors to Match App Theme

**Current:** Purple gradient
**Recommended:** Use your app's teal theme

In `animated_splash_screen.dart` around line 185:

**Light Mode Colors (Teal):**
```dart
colors: [
  const Color(0xFF0D7377),  // Deep Teal
  const Color(0xFF14FFEC),  // Bright Teal
  const Color(0xFF06484A),  // Dark Teal
],
```

**Dark Mode Colors:**
```dart
colors: isDarkMode
  ? [
      const Color(0xFF0F1419),  // Very dark background
      const Color(0xFF1A1F26),  // Dark surface
      const Color(0xFF14FFEC),  // Bright Teal accent
    ]
  : [
      const Color(0xFF0D7377),  // Deep Teal
      const Color(0xFF14FFEC),  // Bright Teal
      const Color(0xFFF8F9FA),  // Light background
    ],
```

#### Change App Name
App name comes from `lib/core/config/app_config.dart`:
```dart
static const String appName = 'Tailor App';  // Change this
```

#### Change Tagline
In `animated_splash_screen.dart` around line 376:
```dart
Text(
  'Your Perfect Fit, Perfectly Managed',  // Change this
  style: TextStyle(/* ... */),
),
```

#### Change Duration
In `lib/core/config/app_config.dart`:
```dart
static const int splashDurationDev = 3000;        // 3 seconds (development)
static const int splashDurationProduction = 2000; // 2 seconds (production)
```

---

## 🚀 STEP-BY-STEP: Complete Customization

### Step 1: Prepare Your Assets

1. **App Icon** (for native splash):
   - Size: 1024x1024 px
   - Location: `assets/images/splash_icon.png`

2. **Logo** (for animated splash):
   - Size: 512x512 px (transparent background recommended)
   - Location: `assets/images/app_logo.png`

### Step 2: Update Native Splash Config

Edit `flutter_native_splash.yaml`:
```yaml
flutter_native_splash:
  color: "#0D7377"  # Your teal color
  image: assets/images/splash_icon.png
  
  android_12:
    image: assets/images/splash_icon.png
    icon_background_color: "#0D7377"
    color: "#0D7377"
  
  ios: true
  web: false
  android: true
  fullscreen: true
```

### Step 3: Generate Native Splash

Run this command in terminal:
```bash
flutter pub run flutter_native_splash:create
```

### Step 4: Update Animated Splash Colors

I'll do this for you automatically to match your app theme.

### Step 5: Test

Run the app:
```bash
flutter run
```

---

## 📋 Quick Customization Checklist

- [ ] **Add splash icon image** to `assets/images/`
- [ ] **Update flutter_native_splash.yaml** with new image path
- [ ] **Change background color** to match brand (#0D7377 for teal)
- [ ] **Run splash generation** command
- [ ] **Update animated splash logo** path if different
- [ ] **Change gradient colors** to match theme
- [ ] **Customize app name** in app_config.dart
- [ ] **Update tagline** text
- [ ] **Adjust duration** if needed
- [ ] **Test on device**

---

## 🎨 Recommended Color Schemes

### Professional Tailor App (Current Theme)
```yaml
# Native Splash
color: "#0D7377"  # Deep Teal

# Animated Splash Gradient
Light: #0D7377 → #14FFEC → #06484A
Dark:  #0F1419 → #1A1F26 → #14FFEC
```

### Elegant Purple (Current Animated Splash)
```yaml
color: "#667eea"
Gradient: #667eea → #764ba2 → #6B73FF
```

### Modern Dark
```yaml
color: "#1A1A2E"
Gradient: #1A1A2E → #16213E → #0F3460
```

---

## 📁 File Locations Summary

| Component | File Location | Purpose |
|-----------|--------------|---------|
| Native Splash Config | `flutter_native_splash.yaml` | Configure first splash |
| Animated Splash | `lib/features/splash/animated_splash_screen.dart` | Custom animation |
| App Config | `lib/core/config/app_config.dart` | App name, duration |
| Splash Icon | `assets/images/splash_icon.png` | Native splash image |
| Animated Logo | `assets/images/app_logo.png` | Animated screen logo |

---

## 🐛 Troubleshooting

### Native splash not changing?
```bash
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter run
```

### Image not showing?
Check `pubspec.yaml` includes:
```yaml
assets:
  - assets/images/
  - assets/icon/
```

### Colors not matching?
Make sure to use the same color format:
- Native: `"#0D7377"` (quotes required)
- Dart: `Color(0xFF0D7377)` (0xFF prefix)

---

## ✅ Next Steps

Would you like me to:
1. Update the splash screens to use your teal theme colors?
2. Change the logo image path?
3. Modify the app name or tagline?
4. Adjust animation duration?

Let me know what you'd like to customize!
