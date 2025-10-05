@echo off
echo.
echo ==============================================
echo Payment Database Constraint Fix Tool
echo ==============================================
echo.

:: Find the database file
set "DB_PATH=%LOCALAPPDATA%\tailor_app\databases\tailor_app.db"

if not exist "%DB_PATH%" (
    echo Database not found at: %DB_PATH%
    echo.
    echo Trying alternative locations...
    
    :: Try Android emulator path
    set "DB_PATH=C:\Users\%USERNAME%\.android\avd\*\userdata-qemu.img.qcow2"
    
    :: This won't work directly, we need to find the actual database
    echo.
    echo Please run the Flutter app at least once to create the database.
    echo Then run this script again.
    pause
    exit /b 1
)

echo Found database at: %DB_PATH%
echo.

:: Check if sqlite3 is available
where sqlite3 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: sqlite3 command not found!
    echo.
    echo Please install SQLite3 and ensure it's in your PATH.
    echo Download from: https://www.sqlite.org/download.html
    echo.
    pause
    exit /b 1
)

echo Applying payment table constraint fix...
echo.

:: Apply the SQL fix
sqlite3 "%DB_PATH%" < fix_payment_constraint.sql

if %ERRORLEVEL% EQ 0 (
    echo.
    echo ✅ SUCCESS: Payment table constraint fix applied successfully!
    echo.
    echo Payment collection should now work properly.
    echo You can test by making a payment in the app.
) else (
    echo.
    echo ❌ ERROR: Failed to apply constraint fix.
    echo Please check the database path and permissions.
)

echo.
pause