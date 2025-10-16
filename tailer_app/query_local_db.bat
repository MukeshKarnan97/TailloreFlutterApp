@echo off
REM Query the local Windows database
echo.
echo ============================================================
echo   TAILOR TABLE DATA - Local Windows Database
echo ============================================================
echo.

set "DB_PATH=C:\Users\mukes\Documents\tailor_app_db\tailor_app.db"

echo Database: %DB_PATH%
echo.

REM Check if sqlite3 is available
where sqlite3 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo SQLite3 command not found. Attempting to use PowerShell...
    echo.
    
    REM Use PowerShell to query the database
    powershell -Command "$db = '%DB_PATH%'; if (Test-Path $db) { Write-Host 'Database exists!'; Write-Host ''; Write-Host '============================================================'; Write-Host '  TABLE SCHEMA'; Write-Host '============================================================'; Write-Host ''; $conn = New-Object System.Data.SQLite.SQLiteConnection('Data Source=' + $db); try { $conn.Open(); $cmd = $conn.CreateCommand(); $cmd.CommandText = 'PRAGMA table_info(tailor)'; $reader = $cmd.ExecuteReader(); while ($reader.Read()) { Write-Host ('Column: ' + $reader[1] + ' | Type: ' + $reader[2] + ' | NotNull: ' + $reader[3] + ' | Default: ' + $reader[4] + ' | PK: ' + $reader[5]); } $reader.Close(); Write-Host ''; Write-Host '============================================================'; Write-Host '  ALL RECORDS'; Write-Host '============================================================'; Write-Host ''; $cmd.CommandText = 'SELECT * FROM tailor'; $reader = $cmd.ExecuteReader(); $count = 0; while ($reader.Read()) { $count++; Write-Host ('--- Record ' + $count + ' ---'); for ($i = 0; $i -lt $reader.FieldCount; $i++) { Write-Host ($reader.GetName($i) + ': ' + $reader[$i]); } Write-Host ''; } $reader.Close(); } catch { Write-Host ('Error: ' + $_.Exception.Message); } finally { $conn.Close(); } } else { Write-Host 'Database not found at:' $db; }"
    
    pause
    exit /b 0
)

echo ============================================================
echo   TABLE SCHEMA
echo ============================================================
echo.
sqlite3 "%DB_PATH%" "PRAGMA table_info(tailor);"
echo.

echo ============================================================
echo   RECORD STATISTICS
echo ============================================================
echo.
sqlite3 "%DB_PATH%" "SELECT 'Total Records:', COUNT(*) FROM tailor;"
sqlite3 "%DB_PATH%" "SELECT 'Active Users:', COUNT(*) FROM tailor WHERE is_active = 1;"
sqlite3 "%DB_PATH%" "SELECT 'Inactive Users:', COUNT(*) FROM tailor WHERE is_active = 0;"
sqlite3 "%DB_PATH%" "SELECT 'Deleted Users:', COUNT(*) FROM tailor WHERE is_deleted = 1;"
echo.

echo ============================================================
echo   ALL TAILOR TABLE DATA (Column Mode)
echo ============================================================
echo.
sqlite3 -header -column "%DB_PATH%" "SELECT * FROM tailor;"
echo.

echo ============================================================
echo   DETAILED VIEW (Row by Row)
echo ============================================================
echo.
sqlite3 -line "%DB_PATH%" "SELECT * FROM tailor;"
echo.

echo ============================================================
echo   ACTIVE USERS ONLY
echo ============================================================
echo.
sqlite3 -header -column "%DB_PATH%" "SELECT id, name, email, phone, is_active, created_at FROM tailor WHERE is_active = 1 AND is_deleted = 0;"
echo.

echo ============================================================
echo   INACTIVE USERS (Pending OTP)
echo ============================================================
echo.
sqlite3 -header -column "%DB_PATH%" "SELECT id, name, email, phone, is_active, created_at FROM tailor WHERE is_active = 0 AND is_deleted = 0;"
echo.

pause
