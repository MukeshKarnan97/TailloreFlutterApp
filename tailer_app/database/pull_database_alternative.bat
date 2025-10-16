@echo off
REM =====================================================
REM  ALTERNATIVE DATABASE PULL METHOD (Without Root)
REM  Uses run-as to access app's private data
REM =====================================================

echo.
echo ========================================
echo   ALTERNATIVE DATABASE PULL (run-as)
echo ========================================
echo.

set PACKAGE_NAME=com.example.tailer_app
set DB_NAME=tailor_app.db
set TEMP_PATH=/sdcard/%DB_NAME%
set LOCAL_DIR=C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database
set LOCAL_FILE=%LOCAL_DIR%\%DB_NAME%

echo [1/7] Checking ADB...
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] ADB not found!
    pause
    exit /b 1
)
echo [OK] ADB is installed
echo.

echo [2/7] Checking device connection...
adb devices | findstr "device$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] No device connected!
    adb devices
    pause
    exit /b 1
)
echo [OK] Device connected
echo.

echo [3/7] Copying database to sdcard using run-as...
echo Command: adb shell "run-as %PACKAGE_NAME% cat databases/%DB_NAME%" ^> "%TEMP_PATH%"
adb shell "run-as %PACKAGE_NAME% cat databases/%DB_NAME%" > "%TEMP_PATH%" 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy with run-as
    echo.
    echo Trying exec-out method...
    adb exec-out run-as %PACKAGE_NAME% cat databases/%DB_NAME% > "%LOCAL_FILE%"
    
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Database pulled successfully using exec-out!
        goto :verify
    ) else (
        echo [ERROR] exec-out method also failed
        echo.
        echo The app may not be debuggable or database doesn't exist.
        echo Make sure:
        echo 1. App is installed and has been run at least once
        echo 2. App is a debug build (not release)
        echo 3. USB debugging is enabled
        pause
        exit /b 1
    )
)

echo [OK] Database copied to sdcard
echo.

echo [4/7] Pulling from sdcard to PC...
adb pull "%TEMP_PATH%" "%LOCAL_FILE%"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to pull from sdcard
    pause
    exit /b 1
)
echo [OK] Database pulled to PC
echo.

echo [5/7] Cleaning up sdcard...
adb shell rm "%TEMP_PATH%"
echo [OK] Temp file removed
echo.

:verify
echo [6/7] Verifying downloaded file...
if exist "%LOCAL_FILE%" (
    echo [OK] File exists: %LOCAL_FILE%
    dir "%LOCAL_FILE%" | findstr "%DB_NAME%"
) else (
    echo [ERROR] File not found: %LOCAL_FILE%
    pause
    exit /b 1
)
echo.

echo [7/7] Checking file content...
powershell -Command "& {$size = (Get-Item '%LOCAL_FILE%').Length; if ($size -gt 0) {Write-Host '[OK] File size:' $size 'bytes'; exit 0} else {Write-Host '[ERROR] File is empty!'; exit 1}}"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Database file might be empty or corrupted
)

echo.
echo ========================================
echo   SUCCESS!
echo ========================================
echo.
echo Database location: %LOCAL_FILE%
echo.
echo Next steps:
echo 1. Open with DB Browser for SQLite
echo 2. Or run: python view_tailor_data.py
echo.
pause
