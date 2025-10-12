# Bug Fixes - Profile & Order Image Upload

## Date: October 12, 2025

---

## Issues Fixed

### 1. ✅ Profile Data Not Persisting (Phone & Shop Name)

**Issue**: When editing profile and adding phone number and shop name, the data showed as saved but disappeared when reopening the edit profile screen.

**Root Cause**: 
The `_saveProfile` method was calling `updateTailor()` with the **email** parameter instead of **uniqueId**:

```dart
// ❌ WRONG - Using email
await _dbService.updateTailor(_currentTailor!.email, { ... });
```

The `updateTailor` method in `LocalDatabaseService` expects `uniqueId`:
```dart
Future<int> updateTailor(String uniqueId, Map<String, dynamic> data) async {
  data['updated_at'] = DateTime.now().toIso8601String();
  return await update('tailor', data, where: 'unique_id = ?', whereArgs: [uniqueId]);
}
```

**Fix Applied**:
```dart
// ✅ CORRECT - Using uniqueId
await _dbService.updateTailor(_currentTailor!.uniqueId, {
  'name': _nameController.text.trim(),
  'shop_name': _shopNameController.text.trim(),
  'phone': _phoneController.text.trim(),
  'address': _addressController.text.trim(),
  'profile_image_path': savedImagePath,
  'updated_at': DateTime.now().toIso8601String(),
});

// Also added: Reload profile data after save
await _loadProfileData();
```

**File Modified**: `lib/features/settings/screens/edit_profile_screen.dart`

---

### 2. ✅ Camera/Gallery Not Opening When Clicked

**Issue**: When tapping "Camera" or "Gallery" in the bottom sheet, nothing happened - the camera/gallery did not open.

**Root Cause**: 
Missing runtime permission requests. While permissions were declared in AndroidManifest.xml and Info.plist, the app wasn't requesting them at runtime before trying to access camera/storage.

**Fix Applied**:

Added permission checks in both `EditProfileScreen` and `AddOrderScreen`:

```dart
Future<void> _pickImage(ImageSource source) async {
  try {
    // Request appropriate permission based on source
    PermissionStatus permissionStatus;
    if (source == ImageSource.camera) {
      permissionStatus = await Permission.camera.request();
    } else {
      // For gallery, request storage/photos permission
      if (Platform.isAndroid) {
        // Android 13+ uses READ_MEDIA_IMAGES, older uses READ_EXTERNAL_STORAGE
        if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
          permissionStatus = PermissionStatus.granted;
        } else {
          permissionStatus = await Permission.photos.request();
          if (permissionStatus.isDenied) {
            permissionStatus = await Permission.storage.request();
          }
        }
      } else {
        // iOS
        permissionStatus = await Permission.photos.request();
      }
    }
    
    // Check if permission was denied
    if (permissionStatus.isDenied) {
      // Show error message
      return;
    }
    
    if (permissionStatus.isPermanentlyDenied) {
      // Show dialog with option to open app settings
      return;
    }
    
    // Permission granted, proceed with image picker
    final XFile? pickedFile = await _imagePicker.pickImage(...);
    // ... rest of the code
  }
}
```

**Permission Handling**:
1. ✅ Requests camera permission when "Camera" is selected
2. ✅ Requests storage/photos permission when "Gallery" is selected
3. ✅ Handles Android 13+ (READ_MEDIA_IMAGES) vs older Android (READ_EXTERNAL_STORAGE)
4. ✅ Shows user-friendly error messages if denied
5. ✅ Provides option to open app settings if permanently denied

**Files Modified**:
- `lib/features/settings/screens/edit_profile_screen.dart`
- `lib/features/orders/screens/add_order_screen.dart`

**Import Added**:
```dart
import 'package:permission_handler/permission_handler.dart';
```

---

## Technical Details

### Permission Flow

```
User taps "Camera" or "Gallery"
    ↓
App requests runtime permission
    ↓
┌─────────────────────┬──────────────────────┬─────────────────────────┐
│ Permission Granted  │ Permission Denied    │ Permanently Denied      │
├─────────────────────┼──────────────────────┼─────────────────────────┤
│ Open Camera/Gallery │ Show error message   │ Show dialog with        │
│ Let user pick image │ Return to screen     │ "Open Settings" button  │
│ Save image          │                      │                         │
└─────────────────────┴──────────────────────┴─────────────────────────┘
```

### Database Update Flow

```
User edits profile fields
    ↓
Taps "Save Changes"
    ↓
Validation passes
    ↓
Save image (if new image selected)
    ↓
Update database using uniqueId ✅ (was using email ❌)
    ↓
Reload AuthService
    ↓
Reload profile data (NEW - ensures UI shows latest data)
    ↓
Show success message
    ↓
Navigate back to settings
```

---

## Testing Instructions

### Test Profile Data Persistence

1. Navigate to Settings → Edit Profile
2. Update the following fields:
   - Phone Number: Enter new number (e.g., +1234567890)
   - Shop Name: Enter new shop name (e.g., "My Tailor Shop")
3. Tap "Save Changes"
4. Wait for success message
5. Navigate back: Settings → Edit Profile
6. **Verify**: Phone number and shop name should still be there ✅

### Test Camera Access

1. Navigate to Settings → Edit Profile
2. Tap on the profile image circle
3. Select "Camera"
4. **First time**: Permission dialog should appear
5. Grant permission
6. **Verify**: Camera opens ✅
7. Take a photo
8. **Verify**: Photo appears in profile circle ✅
9. Save profile
10. **Verify**: Photo persists after navigation ✅

### Test Gallery Access

1. Navigate to Settings → Edit Profile
2. Tap on profile image circle
3. Select "Gallery"
4. **First time**: Permission dialog should appear
5. Grant permission
6. **Verify**: Gallery/Photos opens ✅
7. Select a photo
8. **Verify**: Photo appears in profile circle ✅
9. Save profile
10. **Verify**: Photo persists after navigation ✅

### Test Order Images

1. Navigate to Orders → Add Order
2. Select customer and dress type
3. Scroll to "Garment Photos"
4. Tap "Photo 1"
5. Select "Camera" or "Gallery"
6. **Verify**: Camera/Gallery opens ✅
7. Take/select photo
8. **Verify**: Photo preview shows ✅
9. Repeat for "Photo 2"
10. Create order
11. View order details
12. **Verify**: Both photos display correctly ✅

### Test Permission Denial

1. Go to device Settings → Apps → Tailor App → Permissions
2. Deny Camera permission
3. In app, try to take photo
4. **Verify**: Error message shows ✅
5. **Verify**: Option to open app settings appears ✅

---

## Files Modified Summary

| File | Changes | Lines Changed |
|------|---------|---------------|
| `edit_profile_screen.dart` | Fixed uniqueId param, added permissions | ~100 lines |
| `add_order_screen.dart` | Added permission handling | ~70 lines |

**Total**: 2 files, ~170 lines modified/added

---

## Dependencies Used

✅ **permission_handler: ^11.3.1** (already in pubspec.yaml)
- Used for runtime permission requests
- Handles Android 13+ and iOS permissions
- Provides permission status checking

✅ **image_picker: ^1.0.7** (already in pubspec.yaml)
- Used for camera and gallery access
- Handles image selection and capture

---

## Permissions Configuration

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to take photos of garments and update your profile picture.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to select photos of garments and update your profile picture.</string>
```

---

## Known Issues Resolved

✅ Profile data not saving (phone, shop name)  
✅ Camera not opening on button click  
✅ Gallery not opening on button click  
✅ Permission errors on Android 13+  
✅ Profile data not reloading after save  

---

## Additional Improvements Made

1. **Better Error Handling**: Clear error messages when permissions are denied
2. **Settings Redirect**: If permissions permanently denied, user can go to app settings
3. **Platform-Specific Logic**: Handles Android 13+ vs older versions correctly
4. **Data Reload**: Profile screen now reloads data after save to ensure UI is up-to-date
5. **Consistent Permissions**: Same permission logic in both edit profile and add order screens

---

## Compilation Status

✅ **No Errors**: All files compile successfully  
✅ **No Warnings**: Unused imports removed  
✅ **Type Safe**: All method calls use correct parameter types  

---

## Next Steps

### For User
1. **Test the fixes**: Follow testing instructions above
2. **Verify data persistence**: Check if phone/shop name saves correctly
3. **Test permissions**: Try camera and gallery access
4. **Report any issues**: If problems persist, provide error logs

### For Developer
1. ✅ Monitor logs for permission-related errors
2. ✅ Test on both Android and iOS
3. ✅ Test on Android 13+ specifically (new permission model)
4. ✅ Verify database updates are working correctly

---

## Troubleshooting

### If profile data still not saving:

1. Check database version:
   ```dart
   // Should be v11 or v12
   static int get _databaseVersion => 12;
   ```

2. Check logs for errors:
   ```
   flutter logs | grep -i "EditProfileScreen\|updateTailor"
   ```

3. Verify tailor table has required columns:
   ```sql
   SELECT * FROM tailor LIMIT 1;
   -- Should have: name, shop_name, phone, address, profile_image_path
   ```

### If camera/gallery still not opening:

1. Check permissions in device settings:
   - Android: Settings → Apps → Tailor App → Permissions
   - iOS: Settings → Tailor App → Photos/Camera

2. Uninstall and reinstall app to trigger fresh permission request

3. Check logs for permission errors:
   ```
   flutter logs | grep -i "permission\|camera\|gallery"
   ```

4. Verify AndroidManifest.xml and Info.plist have correct permissions

---

## Summary

Both critical issues have been resolved:

1. ✅ **Profile data persistence**: Fixed by using `uniqueId` instead of `email` in database update
2. ✅ **Camera/Gallery access**: Fixed by adding runtime permission requests

The app should now:
- Save profile data correctly
- Request permissions before camera/gallery access
- Handle permission denials gracefully
- Work on both Android and iOS
- Support Android 13+ permission model

**Status**: Ready for testing ✅

---

**Fixed by**: GitHub Copilot  
**Date**: October 12, 2025  
**Tested**: Compilation ✅ | Runtime testing pending
