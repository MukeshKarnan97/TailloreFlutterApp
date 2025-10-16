# Registration Flow - Error Handling Summary

## Quick Reference: What Happens When API Fails?

### ✅ BEFORE (Old Behavior - BAD)
```
User fills form → Submit → API call fails → Navigate to OTP anyway ❌
```
**Problem:** User could access OTP screen even if registration failed!

### ✅ AFTER (New Behavior - GOOD)
```
User fills form → Submit → API call fails → Show error & STAY on signup screen ✅
```
**Solution:** Only navigate to OTP screen if API succeeds!

---

## Code Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      SIGNUP SCREEN                               │
│  User enters: Name, Email, Password                             │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│              Validate Form (Client-Side)                         │
│  - Email format                                                  │
│  - Password strength                                             │
│  - Required fields                                               │
└───────────────┬─────────────────────────────────────────────────┘
                │
                ▼
        ┌───────────────┐
        │ Valid?        │
        └───┬───────┬───┘
            │       │
        No  │       │ Yes
            │       │
            ▼       ▼
    ┌────────┐  ┌──────────────────────────────────────────┐
    │ Show   │  │  Set Loading = true                      │
    │ Error  │  │  Call: registerWithBackend()             │
    └────────┘  │  POST /api/v1/auth/register/             │
                └───────────────┬──────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   API Call Result     │
                    └───┬───────────┬───────┘
                        │           │
                  Success│           │Error
                        │           │
                        ▼           ▼
        ┌───────────────────────┐  ┌──────────────────────────────┐
        │ ✅ REGISTRATION OK    │  │ ❌ REGISTRATION FAILED       │
        │                       │  │                              │
        │ 1. User created in DB │  │ 1. catch (e) {...}           │
        │ 2. OTP sent to email  │  │ 2. Extract error message     │
        │ 3. Tokens saved       │  │ 3. Show error to user        │
        │ 4. Sync to local DB   │  │ 4. Set Loading = false       │
        └───────┬───────────────┘  └───────┬──────────────────────┘
                │                          │
                ▼                          ▼
    ┌───────────────────────┐    ┌────────────────────────────┐
    │ Show Success Message  │    │ STAY ON SIGNUP SCREEN      │
    │ Set Loading = false   │    │ User can retry             │
    │ Navigate to OTP →     │    │ NO OTP navigation          │
    └───────────────────────┘    └────────────────────────────┘
                │
                ▼
        ┌───────────────────────────────────────┐
        │         OTP SCREEN                    │
        │  Enter OTP from email                 │
        │  Verify → Activate → Login → Dashboard│
        └───────────────────────────────────────┘
```

---

## Error Types & User Messages

### 1. Network Error (No Connection)
```dart
catch (e) {
  if (e.toString().contains('network') || e.toString().contains('connect')) {
    errorMessage = 'Network error. Please check your connection and try again.';
  }
}
```
**User sees:** Red banner with network error message
**Action:** Stay on signup screen

### 2. Email Already Exists
```dart
catch (e) {
  if (e.toString().contains('email')) {
    errorMessage = 'Email already exists. Please use a different email.';
  }
}
```
**User sees:** Red banner with email exists message
**Action:** Stay on signup screen, user changes email

### 3. Validation Error (from backend)
```dart
catch (e) {
  if (e is AuthException) {
    errorMessage = e.userMessage; // e.g., "Password too weak"
  }
}
```
**User sees:** Red banner with specific validation error
**Action:** Stay on signup screen, user fixes issue

### 4. Unknown Error
```dart
catch (e) {
  errorMessage = 'Registration failed: ${e.toString()}';
}
```
**User sees:** Red banner with generic error + details
**Action:** Stay on signup screen

---

## Code Comparison

### OLD CODE (Using AuthService)
```dart
try {
  await _authService.signUpNewUser(
    username: _usernameController.text.trim(),
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );
  
  // Problem: This navigates even if signup didn't hit backend!
  await _navigateToOTP(); ❌
} catch (e) {
  // Error shown but what about local DB state?
  ScaffoldMessenger.showSnackBar(...);
}
```

### NEW CODE (Using HybridAuthService)
```dart
try {
  // ✅ Calls backend API explicitly
  final response = await _authService.registerWithBackend(
    email: _emailController.text.trim(),
    password: _passwordController.text,
    passwordConfirm: _passwordController.text,
    name: _usernameController.text.trim(),
    shopName: '${_usernameController.text.trim()}\'s Shop',
    phone: '',
    address: '',
  );
  
  // ✅ ONLY navigate if API succeeds
  if (mounted) {
    UserFeedbackService.showSuccess(context, 'Check your email for OTP.');
    await _navigateToOTP(); ✅
  }
} catch (e) {
  // ❌ API failed - Stay here, show error
  if (mounted) {
    String errorMessage = extractErrorMessage(e);
    UserFeedbackService.showError(context, errorMessage);
    // NO NAVIGATION - User stays on signup screen
  }
}
```

---

## Testing Commands

### 1. Test Success Path
```bash
# Terminal 1: Start Django backend
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\TailerBackend\tailor_project
python manage.py runserver 192.168.0.11:8000

# Terminal 2: Run Flutter app
cd C:\Users\mukes\Videos\Android_Dev\Devlopment\Tailor_App\tailer_app
flutter run
```

**Expected:**
1. Fill signup form → Submit
2. See loading spinner
3. See "Check your email for OTP" message
4. Navigate to OTP screen
5. Check email for OTP
6. Enter OTP → Verify → Dashboard

### 2. Test Network Error
```bash
# Stop Django backend (Ctrl+C in Terminal 1)

# In Flutter app:
# - Fill signup form → Submit
# - See loading spinner
# - See "Network error" message ✅
# - STAY on signup screen ✅
# - NO OTP screen ✅
```

### 3. Test Email Exists
```bash
# In Flutter app:
# - Use an email you already registered
# - Fill signup form → Submit
# - See loading spinner
# - See "Email already exists" message ✅
# - STAY on signup screen ✅
# - NO OTP screen ✅
```

---

## Summary Table

| Scenario | API Result | Navigation | Message | Local DB |
|----------|-----------|------------|---------|----------|
| Valid signup | ✅ Success (201) | → OTP Screen | "Check email for OTP" | ✅ Inserted |
| Email exists | ❌ Error (400) | Stay on signup | "Email already exists" | ❌ Not inserted |
| No network | ❌ Error (timeout) | Stay on signup | "Network error" | ❌ Not inserted |
| Server down | ❌ Error (500) | Stay on signup | "Registration failed" | ❌ Not inserted |
| Invalid data | ❌ Error (400) | Stay on signup | Validation message | ❌ Not inserted |

---

## Key Takeaways

### ✅ What's Fixed
1. **No invalid OTP access** - Can't reach OTP screen without successful API call
2. **Consistent state** - Local DB only populated when backend succeeds
3. **Clear error messages** - Users know what went wrong
4. **Proper error recovery** - Users can fix issues and retry

### ✅ What's Protected
1. **Backend as source of truth** - All registrations go through API
2. **Data consistency** - Backend and local DB stay in sync
3. **Security** - No local-only registrations or bypasses
4. **User experience** - Clear feedback on success/failure

---

**Created:** 2025-01-14
**Status:** ✅ Implemented & Tested
