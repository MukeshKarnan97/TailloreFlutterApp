# 🚀 Splash Screen Commands - Quick Reference

## Essential Commands

### 1. Generate Native Splash Screen
After updating `flutter_native_splash.yaml` or adding new icon:
```bash
flutter pub run flutter_native_splash:create
```

### 2. Clean Build (if splash not updating)
```bash
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter run
```

### 3. Test on Device
```bash
flutter run
```

### 4. Test Specific Platform
```bash
flutter run -d windows    # Windows
flutter run -d android    # Android
flutter run -d chrome     # Web (if enabled)
```

---

## File Locations to Remember

### Add Your Icon Here:
```
assets/icon/app_icon.png          ← Replace this with your icon
```

### Or Add Custom Splash Icon:
```
assets/images/splash_icon.png     ← Add new custom splash icon here
```

### Configuration Files:
```
flutter_native_splash.yaml        ← Native splash settings
lib/features/splash/
  animated_splash_screen.dart     ← Animated splash code
```

---

## Quick Customization Steps

### Step 1: Add Your Icon
Save your icon (1024x1024 px) as:
- `assets/icon/app_icon.png` (easiest - already configured)

OR

- `assets/images/splash_icon.png` (custom - need to update config)

### Step 2: Update Config (if using custom path)
Edit `flutter_native_splash.yaml`:
```yaml
image: assets/images/splash_icon.png  # Change this line
```

### Step 3: Generate
```bash
flutter pub run flutter_native_splash:create
```

### Step 4: Test
```bash
flutter run
```

---

## Current Configuration Summary

✅ **Native Splash:**
- Color: #0D7377 (Teal)
- Icon: assets/icon/app_icon.png
- Status: Ready to use

✅ **Animated Splash:**
- Colors: Teal gradient
- Logo: assets/images/splash_logo.jpg
- Status: Updated to match theme

---

## What You Need to Do

1. **Replace/Add your icon:**
   - Location: `assets/icon/app_icon.png`
   - Size: 1024x1024 pixels
   - Format: PNG or JPG

2. **Run generation command:**
   ```bash
   flutter pub run flutter_native_splash:create
   ```

3. **Test:**
   ```bash
   flutter run
   ```

**That's it!** Your custom splash screen will be ready. 🎉
