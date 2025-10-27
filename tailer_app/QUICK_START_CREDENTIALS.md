# 🚀 Quick Start: Get Credentials in 10 Minutes

## ⚡ Step 1: Get SHA-1 (Running Now!)

The command is running in your terminal:
```bash
cd android; ./gradlew signingReport
```

**Wait for output showing:**
```
Variant: debug
SHA1: A1:B2:C3:D4:E5:F6:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
```

**Copy the entire SHA1 value!**

---

## ⚡ Step 2: Google Cloud Console (5 minutes)

### A) Enable API
1. Go to: https://console.cloud.google.com/apis/library?project=exchange-maatrax
2. Search: "Google+ API"
3. Click: "Enable"

### B) Create Android Client ID
1. Go to: https://console.cloud.google.com/apis/credentials?project=exchange-maatrax
2. Click: "+ CREATE CREDENTIALS" → "OAuth client ID"
3. Type: **Android**
4. Name: `Tailor App Android`
5. Package: `com.example.tailer_app`
6. SHA-1: **Paste from Step 1**
7. Click: "CREATE"

### C) Create Web Client ID ⭐ (IMPORTANT!)
1. Click: "+ CREATE CREDENTIALS" → "OAuth client ID"
2. Type: **Web application**
3. Name: `Tailor App Backend`
4. Click: "CREATE"
5. **COPY THE CLIENT ID!** (Looks like: `881979011144-xxx...xxx.apps.googleusercontent.com`)

### D) Add to Flutter
Open: `lib/data/services/google_auth_simple.dart`

Line 6, replace:
```dart
const String GOOGLE_WEB_CLIENT_ID = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';
```

With:
```dart
const String GOOGLE_WEB_CLIENT_ID = '881979011144-xxx...xxx.apps.googleusercontent.com';
```

**✅ Google Done!**

---

## ⚡ Step 3: Facebook Developers (5 minutes)

### A) Create App
1. Go to: https://developers.facebook.com/apps
2. Click: "Create App"
3. Type: "Business"
4. Name: `Tailor App`
5. Email: Your email
6. Click: "Create App"

### B) Add Facebook Login
1. Find: "Facebook Login"
2. Click: "Set Up"
3. Select: "Android"

### C) Get Credentials
1. Sidebar: "Settings" → "Basic"
2. **Copy:**
   - App ID: `1234567890123456`
   - App Secret: (Click "Show" and copy)

### D) Generate Key Hash
Run in PowerShell:
```powershell
$env:Path = "C:\Program Files\Git\usr\bin;$env:Path"
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" | openssl sha1 -binary | openssl base64
```
Password: `android`

**Copy the output!** (Like: `lWgFPq3YhbTGPVXhBLbL2bQbD0k=`)

### E) Configure Android Platform
1. Settings → Basic → "Add Platform" → "Android"
2. Package: `com.example.tailer_app`
3. Class: `com.example.tailer_app.MainActivity`
4. Key Hash: **Paste from above**
5. Single Sign On: **ON**
6. Click: "Save Changes"

### F) Add to Flutter
Open: `android/app/src/main/res/values/strings.xml`

Replace with:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">1234567890123456</string>
    <string name="facebook_client_token">your_app_secret_here</string>
    <string name="fb_login_protocol_scheme">fb1234567890123456</string>
</resources>
```

**✅ Facebook Done!**

---

## ⚡ Step 4: Test (2 minutes)

```bash
flutter clean
flutter pub get
flutter run
```

**Click Google button** → Should open Google account picker!
**Click Facebook button** → Should open Facebook login!

---

## 📊 What Data You'll Get

### From Google:
```json
{
  "email": "mukesh@example.com",
  "name": "Mukesh Karnan",
  "photoUrl": "https://lh3.googleusercontent.com/...",
  "idToken": "eyJhbGci..."
}
```

### From Facebook:
```json
{
  "email": "mukesh@example.com",
  "name": "Mukesh Karnan",
  "photoUrl": "https://platform-lookaside.fbsbx.com/...",
  "accessToken": "EAABwzLi..."
}
```

### To Django Backend:
```json
POST /api/accounts/auth/google/
{
  "id_token": "eyJhbGci...",
  "name": "Mukesh Karnan",
  "email": "mukesh@example.com",
  "photo_url": "https://..."
}
```

### From Django:
```json
{
  "access": "eyJ0eXAi...",  // JWT for your app
  "refresh": "eyJ0eXAi...",
  "user": {
    "id": 42,
    "email": "mukesh@example.com",
    "name": "Mukesh Karnan",
    "auth_provider": "google"
  }
}
```

### Saved to SQLite:
```sql
INSERT INTO tailor (id, email, password, full_name)
VALUES (42, 'mukesh@example.com', '[hash]', 'Mukesh Karnan');
```

---

## 🔍 Need More Details?

Read the full guide: **GETTING_CREDENTIALS_AND_DATA_DETAILS.md**

It has:
- Complete step-by-step instructions
- Real-world examples
- All data structures
- Security details
- Troubleshooting

---

## 📋 Checklist

**Google:**
- [ ] SHA-1 obtained ← Check your terminal!
- [ ] Google+ API enabled
- [ ] Android Client ID created
- [ ] Web Client ID created ⭐
- [ ] Added to google_auth_simple.dart

**Facebook:**
- [ ] Facebook App created
- [ ] Facebook Login added
- [ ] App ID & Secret copied
- [ ] Key Hash generated
- [ ] Android platform configured
- [ ] Added to strings.xml

**Test:**
- [ ] flutter clean && flutter pub get
- [ ] flutter run
- [ ] Click Google button
- [ ] Click Facebook button
- [ ] Check console for data
- [ ] Navigate to dashboard

---

**Total Time: ~10-15 minutes** ⏱️

**Your buttons will work immediately after this!** 🚀
