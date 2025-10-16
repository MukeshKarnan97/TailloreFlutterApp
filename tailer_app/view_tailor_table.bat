@echo off
REM Script to view tailor table data from Android device
REM Make sure you have ADB installed and device connected

echo.
echo ============================================================
echo   TAILOR TABLE DATA VIEWER
echo ============================================================
echo.

REM Check if ADB is available
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ADB not found in PATH
    echo Please install Android SDK Platform Tools
    echo Download from: https://developer.android.com/studio/releases/platform-tools
    echo.
    pause
    exit /b 1
)

REM Check if device is connected
echo Checking for connected devices...
adb devices | findstr /r "device$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No Android device connected
    echo Please connect your device via USB and enable USB debugging
    echo.
    pause
    exit /b 1
)

echo Device found!
echo.

REM Database path
set "DB_PATH=/data/user/0/com.example.tailer_app/databases/tailor_app.db"

echo ============================================================
echo   DATABASE INFO
echo ============================================================
echo Path: %DB_PATH%
echo.

REM Check if database exists
echo Checking if database exists...
adb shell "ls %DB_PATH%" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Database file not found at %DB_PATH%
    echo Please run the app first to create the database
    echo.
    pause
    exit /b 1
)

echo Database found!
echo.

echo ============================================================
echo   TABLE SCHEMA
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% 'PRAGMA table_info(tailor);'" 2>nul
echo.

echo ============================================================
echo   RECORD COUNT
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% 'SELECT COUNT(*) as total_records FROM tailor;'" 2>nul
echo.

echo ============================================================
echo   ACTIVE/INACTIVE COUNT
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% 'SELECT COUNT(*) as active_users FROM tailor WHERE is_active = 1;'" 2>nul
adb shell "sqlite3 %DB_PATH% 'SELECT COUNT(*) as inactive_users FROM tailor WHERE is_active = 0;'" 2>nul
echo.

echo ============================================================
echo   ALL TAILOR TABLE DATA
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% '.mode column' '.headers on' 'SELECT * FROM tailor;'" 2>nul
echo.

echo ============================================================
echo   DETAILED VIEW (Row by Row)
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% '.mode line' 'SELECT * FROM tailor;'" 2>nul
echo.

echo ============================================================
echo   ACTIVE USERS ONLY
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% '.mode column' '.headers on' 'SELECT id, name, email, phone, is_active, created_at FROM tailor WHERE is_active = 1;'" 2>nul
echo.

echo ============================================================
echo   INACTIVE USERS (Pending OTP)
echo ============================================================
echo.
adb shell "sqlite3 %DB_PATH% '.mode column' '.headers on' 'SELECT id, name, email, phone, is_active, created_at FROM tailor WHERE is_active = 0;'" 2>nul
echo.

echo ============================================================
echo   DATA EXPORT COMPLETE
echo ============================================================
echo.
echo Press any key to exit...
pause >nul
