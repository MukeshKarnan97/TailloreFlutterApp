@echo off
REM Database Debug Script for Windows
REM This script helps you locate and inspect the database

echo.
echo ============================================================
echo   DATABASE DEBUG TOOL - Tailor App
echo ============================================================
echo.

REM Check for common database locations on Windows
set "DB_NAME=tailor_app.db"

echo Searching for database file: %DB_NAME%
echo.

REM Common locations for Flutter app databases on Windows
set "APPDATA_DB=%LOCALAPPDATA%\tailer_app\app_flutter\%DB_NAME%"
set "TEMP_DB=%TEMP%\%DB_NAME%"

echo Checking common locations:
echo.

echo 1. AppData Location:
echo    %APPDATA_DB%
if exist "%APPDATA_DB%" (
    echo    [32m✓ FOUND![0m
    set "FOUND_PATH=%APPDATA_DB%"
    goto :show_info
) else (
    echo    [31m✗ Not found[0m
)
echo.

echo 2. Temp Location:
echo    %TEMP_DB%
if exist "%TEMP_DB%" (
    echo    [32m✓ FOUND![0m
    set "FOUND_PATH=%TEMP_DB%"
    goto :show_info
) else (
    echo    [31m✗ Not found[0m
)
echo.

REM Search in user profile
echo 3. Searching in user profile...
for /f "delims=" %%i in ('dir /s /b "%USERPROFILE%\%DB_NAME%" 2^>nul') do (
    echo    [32m✓ FOUND: %%i[0m
    set "FOUND_PATH=%%i"
    goto :show_info
)

echo    [31m✗ Not found in user profile[0m
echo.

echo [33m⚠ Database file not found in common locations[0m
echo.
echo Possible reasons:
echo   - App hasn't been run yet (database not created)
echo   - Using a different database name
echo   - Database in a non-standard location
echo.
echo Tip: Run the app first to create the database, then run this script again.
echo.
goto :end

:show_info
echo.
echo ============================================================
echo   DATABASE FOUND!
echo ============================================================
echo.
echo Full Path:
echo %FOUND_PATH%
echo.

REM Get file size
for %%A in ("%FOUND_PATH%") do set "SIZE=%%~zA"
echo File Size: %SIZE% bytes
echo.

REM Get file date
for %%A in ("%FOUND_PATH%") do set "DATE=%%~tA"
echo Last Modified: %DATE%
echo.

echo ============================================================
echo   INSPECTION OPTIONS
echo ============================================================
echo.
echo You can inspect this database using:
echo.
echo 1. SQLite Browser (Recommended):
echo    Download from: https://sqlitebrowser.org/
echo    Then open: %FOUND_PATH%
echo.
echo 2. Command Line SQLite:
echo    sqlite3 "%FOUND_PATH%"
echo.
echo 3. VS Code Extension:
echo    Install "SQLite Viewer" extension
echo    Then open: %FOUND_PATH%
echo.
echo 4. Run Flutter Debug Screen:
echo    Add DatabaseDebugScreen to your app routes
echo    Navigate to /debug-database
echo.

echo ============================================================
echo   QUICK QUERIES
echo ============================================================
echo.
echo To check tailor table records, run:
echo.
echo sqlite3 "%FOUND_PATH%" "SELECT COUNT(*) as total, SUM(CASE WHEN is_active=1 THEN 1 ELSE 0 END) as active, SUM(CASE WHEN is_active=0 THEN 1 ELSE 0 END) as inactive FROM tailor;"
echo.

:end
echo.
echo Press any key to exit...
pause >nul
