@echo off
REM Script to pull SQLite database from Android device
REM Target directory: C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database

echo.
echo ============================================================
echo   PULL DATABASE FROM ANDROID DEVICE
echo ============================================================
echo.

REM Set paths
set "TARGET_DIR=C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database"
set "DEVICE_DB_PATH=/data/user/0/com.example.tailer_app/databases/tailor_app.db"
set "LOCAL_DB_FILE=%TARGET_DIR%\tailor_app.db"

REM Check if ADB is available
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ADB not found!
    echo.
    echo Please install Android SDK Platform Tools:
    echo 1. Download from: https://developer.android.com/studio/releases/platform-tools
    echo 2. Extract to a folder (e.g., C:\platform-tools)
    echo 3. Add to PATH: 
    echo    - Windows Key + Search "Environment Variables"
    echo    - Edit System Environment Variables
    echo    - Click "Environment Variables"
    echo    - Under "System Variables", select "Path" and click "Edit"
    echo    - Click "New" and add: C:\platform-tools
    echo    - Click OK and restart terminal
    echo.
    echo OR use the portable method:
    echo    Place adb.exe in this folder and run again
    echo.
    pause
    exit /b 1
)

echo ✅ ADB found!
echo.

REM Check if device is connected
echo Checking for connected devices...
adb devices | findstr /r "device$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: No Android device connected!
    echo.
    echo Please:
    echo 1. Connect your Android device via USB
    echo 2. Enable USB Debugging:
    echo    - Go to Settings → About Phone
    echo    - Tap "Build Number" 7 times to enable Developer Options
    echo    - Go to Settings → Developer Options
    echo    - Enable "USB Debugging"
    echo 3. Accept the USB debugging prompt on your device
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

echo ✅ Device connected!
echo.

REM List connected devices
echo Connected devices:
adb devices
echo.

REM Create target directory if it doesn't exist
if not exist "%TARGET_DIR%" (
    echo Creating directory: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
)

echo Target directory: %TARGET_DIR%
echo.

REM Check if database exists on device
echo Checking if database exists on device...
adb shell "ls %DEVICE_DB_PATH%" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Database not found on device!
    echo Path: %DEVICE_DB_PATH%
    echo.
    echo Please make sure:
    echo 1. The app is installed on the device
    echo 2. You have run the app at least once to create the database
    echo 3. The package name is correct: com.example.tailer_app
    echo.
    pause
    exit /b 1
)

echo ✅ Database found on device!
echo.

REM Pull the database
echo ============================================================
echo   PULLING DATABASE...
echo ============================================================
echo.
echo From: %DEVICE_DB_PATH%
echo To:   %LOCAL_DB_FILE%
echo.

adb pull %DEVICE_DB_PATH% "%LOCAL_DB_FILE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to pull database!
    echo.
    echo This might be due to permissions. Try running with root:
    echo    adb root
    echo    adb pull %DEVICE_DB_PATH% "%LOCAL_DB_FILE%"
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS!
echo ============================================================
echo.

if exist "%LOCAL_DB_FILE%" (
    echo ✅ Database pulled successfully!
    echo.
    echo Location: %LOCAL_DB_FILE%
    
    REM Get file size
    for %%A in ("%LOCAL_DB_FILE%") do set SIZE=%%~zA
    echo Size: %SIZE% bytes
    
    REM Get file date
    for %%A in ("%LOCAL_DB_FILE%") do set DATE=%%~tA
    echo Modified: %DATE%
    echo.
    
    echo ============================================================
    echo   WHAT TO DO NEXT
    echo ============================================================
    echo.
    echo You can now inspect the database using:
    echo.
    echo 1. DB Browser for SQLite (Recommended):
    echo    Download: https://sqlitebrowser.org/
    echo    Open: %LOCAL_DB_FILE%
    echo.
    echo 2. VS Code SQLite Extension:
    echo    Install "SQLite Viewer" extension
    echo    Right-click file ^> Open Database
    echo.
    echo 3. Command Line:
    echo    sqlite3 "%LOCAL_DB_FILE%"
    echo    .tables
    echo    SELECT * FROM tailor;
    echo.
    echo 4. Python script:
    echo    Run: python view_tailor_data.py
    echo.
) else (
    echo ❌ Database file not found after pull!
)

echo.
pause
