# Quick Test Guide - Forgot Password Flow

## 🎯 Quick Test (5 minutes)

### Test User Details
- **Email:** mukesh.dmc97@gmail.com
- **Current Password:** Admin#234
- **User ID:** MATF19JU7Z

### Step-by-Step Test

#### 1. Start Forgot Password Flow (30 seconds)
```
1. Open app → Sign In screen
2. Click "Forgot Password?" link
3. Enter email: mukesh.dmc97@gmail.com
4. Click "Send OTP" button
5. ✅ Should see success message: "OTP sent to your email!"
```

#### 2. Check Email for OTP (1 minute)
```
1. Open email inbox for mukesh.dmc97@gmail.com
2. Look for password reset email
3. Find 6-digit OTP code
4. Note: OTP typically expires in 10-15 minutes
```

#### 3. Enter OTP and New Password (1 minute)
```
1. On Reset Password screen, enter 6-digit OTP
   (Fields auto-focus, just type the numbers)

2. Enter NEW password: "NewPass123!"
   ✅ Must meet requirements:
      - 8+ characters
      - 1 uppercase (N, P)
      - 1 lowercase (e, w, a, s, s)
      - 1 number (1, 2, 3)
      - 1 special char (!, #)

3. Confirm password: "NewPass123!"
   (Must match exactly)

4. Click "Reset Password" button
```

#### 4. Verify Success (30 seconds)
```
1. ✅ Should see: "Password reset successful! Please sign in with your new password."
2. ✅ Should auto-redirect to Sign In screen after 1.5 seconds
```

#### 5. Test New Password (30 seconds)
```
1. On Sign In screen:
   Email: mukesh.dmc97@gmail.com
   Password: NewPass123!

2. Click "Sign In"
3. ✅ Should login successfully
4. ✅ Should navigate to home/dashboard
```

#### 6. Verify Database (1 minute)
```
1. Go back to Sign In screen
2. Click purple bug icon (bottom-left)
3. Find user: mukesh.dmc97@gmail.com
4. Check password_hash:
   ✅ Should be 64 characters (green highlight)
   ✅ Should be DIFFERENT from original hash

5. Test old password:
   - Enter: "Admin#234"
   - Click "Test Password"
   - ❌ Should NOT match (hash changed)

6. Test new password:
   - Enter: "NewPass123!"
   - Click "Test Password"
   - ✅ Should MATCH current hash
```

## 🧪 Test Scenarios

### Scenario 1: Invalid OTP ❌
```
Flow: Forgot Password → Enter wrong OTP
Expected: Error message "Invalid or expired OTP"
Time: 1 minute
```

### Scenario 2: Weak Password ❌
```
Flow: Forgot Password → Valid OTP → Weak password
Test passwords:
- "Pass" → Too short (< 8 chars)
- "password123" → No uppercase
- "PASSWORD123" → No lowercase  
- "Password123" → No special character

Expected: Validation error messages
Time: 2 minutes
```

### Scenario 3: Password Mismatch ❌
```
Flow: Forgot Password → Valid OTP
New Password: "Pass123!"
Confirm Password: "Pass123#"

Expected: "Passwords do not match"
Time: 1 minute
```

### Scenario 4: Resend OTP 🔄
```
Flow: Forgot Password → Wait on Reset screen
1. Try clicking "Resend Code" immediately
   ✅ Should be disabled (countdown showing)

2. Wait 60 seconds

3. Click "Resend Code"
   ✅ Should send new OTP
   ✅ Timer restarts to 60 seconds

Time: 2 minutes (includes waiting)
```

### Scenario 5: Back Navigation ⬅️
```
Flow: Forgot Password → Reset Password screen
1. Click back arrow (top-left)
   ✅ Should go back to Forgot Password

2. From Forgot Password → Click back arrow
   ✅ Should go back to Sign In

Time: 30 seconds
```

## 📊 Expected Results Summary

| Test | Action | Expected Result |
|------|--------|----------------|
| 1 | Enter email + Send OTP | "OTP sent" message + navigate to reset screen |
| 2 | Enter valid OTP + strong password | "Password reset successful" + redirect to sign-in |
| 3 | Sign in with new password | Login successful |
| 4 | Check database hash | 64-char hash, different from old |
| 5 | Test old password in debug | Does NOT match |
| 6 | Test new password in debug | MATCHES |
| 7 | Invalid OTP | Error message |
| 8 | Weak password | Validation error |
| 9 | Password mismatch | "Passwords do not match" |
| 10 | Resend OTP | New code sent, timer restart |

## 🔍 Troubleshooting

### Issue: "OTP sent" but no email received
**Solutions:**
1. Check spam/junk folder
2. Verify email address is correct
3. Check backend logs for email service errors
4. Try with different email

### Issue: "Invalid or expired OTP"
**Solutions:**
1. OTP expired (usually 10-15 min validity)
2. Wrong OTP code entered
3. Click "Resend Code" to get new OTP
4. Make sure no extra spaces in OTP

### Issue: Password validation failing
**Check:**
- Length ≥ 8 characters ✓
- Has uppercase letter ✓
- Has lowercase letter ✓
- Has number ✓
- Has special character ✓

Example valid: `NewPass123!`, `Admin#234`, `Test@2024`

### Issue: "Failed to send OTP"
**Solutions:**
1. Check internet connection
2. Check if API server is running (http://192.168.0.7:8000)
3. Verify user exists in database
4. Check backend logs

### Issue: Sign-in fails after reset
**Check:**
1. Using correct NEW password (not old)
2. Password was actually updated (check database)
3. No typos in email/password
4. Try debug screen password test

## 🎓 What's Being Tested

### Backend Integration ✅
- `/api/v1/auth/forgot-password/` endpoint
- `/api/v1/auth/reset-password/` endpoint
- OTP generation and validation
- Password hash update on server

### Local Database Sync ✅
- Password hash generated (SHA256)
- Local `tailor` table updated
- `password_hash` field changed
- `updated_at` timestamp set

### User Experience ✅
- Smooth navigation flow
- Clear error messages
- Loading states
- Success feedback
- Form validation

### Security ✅
- Strong password requirements
- OTP expiry
- Password hashing (one-way)
- No plaintext passwords stored

## ⏱️ Total Test Time

- **Quick Happy Path:** 5 minutes
- **All Scenarios:** 10 minutes
- **Database Verification:** 2 minutes
- **Total Complete Test:** ~15 minutes

## 📝 Test Checklist

```
[ ] 1. Forgot password link works
[ ] 2. Email validation works
[ ] 3. OTP sent successfully
[ ] 4. Email received with OTP
[ ] 5. Reset screen shows with email
[ ] 6. OTP fields work (auto-focus)
[ ] 7. Password validation works
[ ] 8. Passwords match validation
[ ] 9. Submit button works
[ ] 10. Success message appears
[ ] 11. Redirect to sign-in works
[ ] 12. New password login works
[ ] 13. Database hash updated
[ ] 14. Old password no longer works
[ ] 15. New password matches DB hash
[ ] 16. Resend OTP works
[ ] 17. Timer countdown works
[ ] 18. Back navigation works
[ ] 19. Error handling works
[ ] 20. Invalid OTP rejected
```

## 🚀 Ready to Test!

Everything is set up and ready. Just follow the steps above and check off the items as you go. The implementation is complete and should work end-to-end! 🎉
