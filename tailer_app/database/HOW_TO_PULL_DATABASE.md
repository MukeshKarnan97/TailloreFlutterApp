# 📥 How to Pull Database from Android Device

## 🎯 Goal
Pull the SQLite database from your Android device to:
```
C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\
```

---

## 📋 Prerequisites

### 1. Install ADB (Android Debug Bridge)

**Option A: Install Android SDK Platform Tools (Recommended)**
1. Download from: https://developer.android.com/studio/releases/platform-tools
2. Extract to: `C:\platform-tools\`
3. Add to PATH:
   - Open System Properties → Advanced → Environment Variables
   - Edit `Path` variable
   - Add: `C:\platform-tools\`
   - Click OK and restart terminal

**Option B: Install via Chocolatey (Windows Package Manager)**
```powershell
# Install Chocolatey first (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install ADB
choco install adb
```

**Option C: Install Android Studio (Full SDK)**
1. Download from: https://developer.android.com/studio
2. Install Android Studio
3. SDK Manager → Install "Android SDK Platform-Tools"
4. Add to PATH: `C:\Users\<USERNAME>\AppData\Local\Android\Sdk\platform-tools\`

---

## 📱 Setup Android Device

### 1. Enable Developer Options
1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times
3. You'll see "You are now a developer!"

### 2. Enable USB Debugging
1. Go to **Settings** → **Developer Options**
2. Turn on **USB Debugging**
3. (Optional) Turn on **Stay Awake** (keeps screen on while charging)

### 3. Connect Device
1. Connect your Android phone to PC via USB cable
2. On your phone, you'll see a prompt: **"Allow USB debugging?"**
3. Check **"Always allow from this computer"**
4. Tap **OK**

---

## 🔍 Verify ADB Connection

Open PowerShell or Command Prompt and run:

```powershell
# Check if ADB is installed
adb version

# List connected devices
adb devices
```

**Expected Output:**
```
List of devices attached
ABC123XYZ    device
```

If you see "unauthorized", check your phone for the USB debugging prompt.

---

## 📥 Pull Database from Android

### Method 1: Using ADB Command (Direct)

```powershell
# Navigate to target directory
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database

# Pull the database
adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db tailor_app.db
```

### Method 2: Using Full Path

```powershell
adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\tailor_app.db"
```

### Method 3: Pull All Database Files

```powershell
# Pull entire databases folder
adb pull /data/user/0/com.example.tailer_app/databases/ "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\"
```

---

## 🚨 Troubleshooting

### Issue 1: "adb: command not found"
**Solution:** ADB is not installed or not in PATH
- Install ADB (see Prerequisites above)
- Add to PATH environment variable
- Restart terminal/PowerShell

### Issue 2: "no devices/emulators found"
**Solution:** Device not connected or USB debugging not enabled
- Check USB cable connection
- Enable USB debugging in Developer Options
- Run `adb devices` to verify

### Issue 3: "device unauthorized"
**Solution:** USB debugging not authorized
- Check phone screen for prompt
- Tap "Allow" and check "Always allow"
- Run `adb devices` again

### Issue 4: "remote object '/data/user/0/...' does not exist"
**Solution:** App not installed or different package name
- Make sure app is installed and has been run at least once
- Verify package name: `adb shell pm list packages | grep tailer`
- Check if database exists: `adb shell ls /data/user/0/com.example.tailer_app/databases/`

### Issue 5: "Permission denied"
**Solution:** Need root access or run-as
- Try: `adb shell run-as com.example.tailer_app cp databases/tailor_app.db /sdcard/`
- Then: `adb pull /sdcard/tailor_app.db`
- Or use a rooted device

---

## 🛠️ Automated Script

I've created a batch script for you! Just run it:

```powershell
.\pull_database.bat
```

This script will:
1. ✅ Check if ADB is installed
2. ✅ Check if device is connected
3. ✅ Create target directory if needed
4. ✅ Pull database from device
5. ✅ Verify download successful
6. ✅ Show database info

---

## 📊 View Database After Pulling

### Option 1: DB Browser for SQLite (Recommended)
1. Download: https://sqlitebrowser.org/
2. Install and open
3. File → Open Database
4. Select: `C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\tailor_app.db`
5. Browse "tailor" table

### Option 2: VS Code Extension
1. Install "SQLite Viewer" extension in VS Code
2. Right-click `tailor_app.db` file
3. Select "Open Database"

### Option 3: Command Line (sqlite3)
```powershell
# Install sqlite3 (if not installed)
choco install sqlite

# Query database
sqlite3 "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\tailor_app.db"

# Then run SQL commands:
.tables
.schema tailor
SELECT * FROM tailor;
```

### Option 4: Python Script
```powershell
python view_tailor_data.py
```

---

## 🔄 Re-pull Database (Update)

To get the latest version of the database:

```powershell
# Pull again (overwrites existing file)
adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db "C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\tailor_app.db"
```

---

## 📝 Quick Reference Commands

```powershell
# Check ADB version
adb version

# List devices
adb devices

# List all packages
adb shell pm list packages | grep tailer

# Check if database exists
adb shell ls /data/user/0/com.example.tailer_app/databases/

# Pull database
adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db ./

# Push database back (for testing)
adb push tailor_app.db /data/user/0/com.example.tailer_app/databases/

# Restart ADB server (if issues)
adb kill-server
adb start-server
```

---

## 🎯 Summary

**Step-by-step to pull your database:**

1. ✅ Install ADB
2. ✅ Enable USB Debugging on phone
3. ✅ Connect phone to PC
4. ✅ Open PowerShell/Terminal
5. ✅ Run: `cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database`
6. ✅ Run: `adb pull /data/user/0/com.example.tailer_app/databases/tailor_app.db tailor_app.db`
7. ✅ Open database with DB Browser for SQLite

---

**Last Updated:** October 16, 2025  
**Target Directory:** `C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app\database\`
