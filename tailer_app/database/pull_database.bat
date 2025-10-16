@echo off
REM =====================================================
REM  PULL DATABASE FROM ANDROID DEVICE
REM  Target: C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database
REM =====================================================

echo.
echo ========================================
echo   ANDROID DATABASE PULL SCRIPT
echo ========================================
echo.

REM Set variables
set PACKAGE_NAME=com.example.tailer_app
set DB_NAME=tailor_app.db
set DEVICE_PATH=/data/user/0/%PACKAGE_NAME%/databases/%DB_NAME%
set LOCAL_DIR=C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database
set LOCAL_FILE=%LOCAL_DIR%\%DB_NAME%

echo [1/6] Checking if ADB is installed...
echo.

where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] ADB is not installed or not in PATH!
    echo.
    echo Please install Android SDK Platform Tools:
    echo 1. Download from: https://developer.android.com/studio/releases/platform-tools
    echo 2. Extract to C:\platform-tools\
    echo 3. Add to PATH environment variable
    echo 4. Restart this script
    echo.
    pause
    exit /b 1
)

echo [OK] ADB is installed!
adb version | findstr "Android Debug Bridge"
echo.

echo [2/6] Checking connected devices...
echo.

adb devices | findstr "device$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] No Android device connected!
    echo.
    echo Please:
    echo 1. Connect your Android device via USB
    echo 2. Enable USB Debugging in Developer Options
    echo 3. Accept "Allow USB debugging?" prompt on your phone
    echo 4. Run this script again
    echo.
    echo Current devices:
    adb devices
    echo.
    pause
    exit /b 1
)

echo [OK] Device connected!
adb devices
echo.

echo [3/6] Checking if database exists on device...
echo.

adb shell "ls %DEVICE_PATH%" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Database not found on device!
    echo.
    echo Database path: %DEVICE_PATH%
    echo.
    echo Please:
    echo 1. Make sure the app is installed
    echo 2. Open the app at least once
    echo 3. Sign up or sign in to create database
    echo.
    echo Checking what databases exist:
    adb shell "ls /data/user/0/%PACKAGE_NAME%/databases/ 2>/dev/null || echo 'No databases folder found'"
    echo.
    pause
    exit /b 1
)

echo [OK] Database exists on device!
adb shell "ls -lh %DEVICE_PATH%"
echo.

echo [4/6] Creating target directory...
echo.

if not exist "%LOCAL_DIR%" (
    mkdir "%LOCAL_DIR%"
    echo [OK] Created directory: %LOCAL_DIR%
) else (
    echo [OK] Directory already exists: %LOCAL_DIR%
)
echo.

echo [5/6] Pulling database from device...
echo.
echo From: %DEVICE_PATH%
echo To:   %LOCAL_FILE%
echo.

adb pull %DEVICE_PATH% "%LOCAL_FILE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to pull database!
    echo.
    echo This might be a permission issue. Try alternative method:
    echo.
    echo Run these commands manually:
    echo   adb shell run-as %PACKAGE_NAME% cp databases/%DB_NAME% /sdcard/
    echo   adb pull /sdcard/%DB_NAME% "%LOCAL_FILE%"
    echo   adb shell rm /sdcard/%DB_NAME%
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Database pulled successfully!
echo.

echo [6/6] Verifying downloaded file...
echo.

if exist "%LOCAL_FILE%" (
    echo [OK] File exists: %LOCAL_FILE%
    echo.
    echo File details:
    dir "%LOCAL_FILE%" | findstr "%DB_NAME%"
    echo.
    echo ========================================
    echo   SUCCESS! Database pulled successfully
    echo ========================================
    echo.
    echo Database location:
    echo %LOCAL_FILE%
    echo.
    echo Next steps:
    echo 1. Open with DB Browser for SQLite
    echo 2. Or run: python view_tailor_data.py
    echo 3. Or open in VS Code with SQLite extension
    echo.
) else (
    echo [ERROR] File not found after pull!
    echo Expected location: %LOCAL_FILE%
    echo.
)

pause
