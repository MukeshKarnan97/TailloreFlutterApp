@echo off
REM =====================================================
REM  COMPLETE APP STARTUP & DATABASE CHECK
REM  Run this before testing the app
REM =====================================================

echo.
echo ========================================
echo   TAILOR APP - STARTUP SEQUENCE
echo ========================================
echo.

echo [STEP 1/5] Checking Flutter installation...
flutter --version | findstr "Flutter"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    pause
    exit /b 1
)
echo [OK] Flutter is installed
echo.

echo [STEP 2/5] Cleaning build artifacts...
flutter clean
echo [OK] Build artifacts cleaned
echo.

echo [STEP 3/5] Getting dependencies...
flutter pub get
echo [OK] Dependencies fetched
echo.

echo [STEP 4/5] Checking connected devices...
flutter devices
echo.
echo [INFO] Make sure your Android device is connected!
echo Press any key to continue...
pause >nul
echo.

echo [STEP 5/5] Running app with database initialization...
echo.
echo ========================================
echo   STARTING APP
echo ========================================
echo.
echo Watch for these messages in logs:
echo   ✅ "DATABASE INITIALIZATION"
echo   ✅ "Database file confirmed to exist"
echo   ✅ "is_active column exists"
echo   ✅ "DATABASE INITIALIZATION COMPLETED"
echo.
echo Press CTRL+C to stop the app
echo.

REM Run the app in debug mode
flutter run

echo.
echo ========================================
echo   APP STOPPED
echo ========================================
echo.

pause
