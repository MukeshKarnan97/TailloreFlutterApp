@echo off
REM Quick Test Script for Auth Fix
echo ============================================
echo   AUTH FIX - QUICK TEST
echo ============================================
echo.

echo Step 1: Checking if device is connected...
adb devices
if %errorlevel% neq 0 (
    echo ERROR: ADB not found or device not connected
    pause
    exit /b 1
)
echo.

echo Step 2: Running database checker...
echo This will show user data and is_active status
echo.
flutter run lib/check_database.dart
echo.

echo ============================================
echo   TEST COMPLETE
echo ============================================
echo.
echo Next: Test login with these credentials:
echo   Email: mukesh.dmc97@gmail.com
echo   Password: Admin#234
echo.
echo Expected: Login should work and dashboard should load
echo.
pause
