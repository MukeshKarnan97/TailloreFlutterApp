# 🚀 Complete GoRouter Named Routes Migration Guide

## 📋 **Quick Reference: Old → New Pattern**

```dart
// ❌ OLD WAY
context.go('/dashboard');
context.go('/customers/details/${customerId}');
context.push('/auth/otp');

// ✅ NEW WAY
context.goNamed(RouteNames.dashboard);
context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': customerId});
context.pushNamed(RouteNames.otp, extra: {...});
```

---

## 🔄 **Complete Migration Map**

### **1. Import Required**
Add to every file using navigation:
```dart
import 'package:tailer_app/routes/app_routes.dart';
```

### **2. Auth Screens**

#### **signin_screen.dart**
```dart
// Line ~110
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);

// Line ~132  
context.push('/auth/forgot_password'); → context.pushNamed(RouteNames.forgotPassword);

// Line ~165
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);

// Line ~178
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);
```

#### **signup_screen.dart**
```dart
// Line ~147
context.push('/auth/otp', extra: {...}); → context.pushNamed(RouteNames.otp, extra: {...});

// Line ~178
context.go('/auth/sign-in'); → context.goNamed(RouteNames.signIn);

// Line ~210 & ~223
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);
```

#### **forgot_password_screen.dart**
```dart
// Line ~71
context.push("/auth/otp", extra: {...}); → context.pushNamed(RouteNames.otp, extra: {...});

// Line ~122
context.push('/auth/password-reset', extra: {...}); → context.pushNamed(RouteNames.passwordReset, extra: {...});
```

#### **password_reset.dart**
```dart
// Line ~75 & ~224
context.go('/auth/sign-in'); → context.goNamed(RouteNames.signIn);
```

#### **AuthGoogleButton.dart**
```dart
// Line ~89
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);
```

#### **AuthFooter.dart**
```dart
// Line ~37
context.push(route); → context.pushNamed(routeName); // Need to pass route name instead
```

---

### **3. Customer Screens**

#### **customer_profile_screen.dart**
```dart
// Line ~28
context.go('/customers'); → context.goNamed(RouteNames.customers);

// Line ~170
context.go('/customers/add'); → context.goNamed(RouteNames.addCustomer);

// Line ~182
context.go('/customers/view'); → context.goNamed(RouteNames.viewCustomers);
```

#### **add_customer_screen.dart**
```dart
// Line ~38 & ~429
context.go('/customers/profile'); → context.goNamed(RouteNames.customerProfile);

// Line ~561
context.go('/customers/view'); → context.goNamed(RouteNames.viewCustomers);
```

#### **view_customers_screen.dart**
```dart
// Line ~85
context.go('/customers/profile'); → context.goNamed(RouteNames.customerProfile);

// Line ~107
context.go('/customers/add'); → context.goNamed(RouteNames.addCustomer);

// Line ~510
context.go('/customers/details/${customer.id}'); → 
context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': customer.id});

// Line ~514
context.go('/customers/edit/${customer.id}'); → 
context.goNamed(RouteNames.editCustomer, pathParameters: {'customerId': customer.id});
```

#### **customer_details_screen.dart**
```dart
// Line ~55 & ~83
context.go('/customers/view'); → context.goNamed(RouteNames.viewCustomers);

// Line ~445
context.go('/customers/edit/${widget.customerId}'); → 
context.goNamed(RouteNames.editCustomer, pathParameters: {'customerId': widget.customerId});

// Line ~464
context.go('/measurements/list/${widget.customerId}'); → 
context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId});
```

#### **edit_customer_screen.dart**
```dart
// Line ~67
context.go('/customers/view'); → context.goNamed(RouteNames.viewCustomers);

// Line ~98 & ~489 & ~614
context.go('/customers/details/${widget.customerId}'); → 
context.goNamed(RouteNames.customerDetails, pathParameters: {'customerId': widget.customerId});

// Line ~682
context.go('/customers/view'); → context.goNamed(RouteNames.viewCustomers);
```

---

### **4. Measurement Screens**

#### **add_measurement_screen.dart**
```dart
// Line ~67
context.go('/measurements/category/${widget.customerId}'); → 
context.goNamed(RouteNames.measurementCategory, pathParameters: {'customerId': widget.customerId});

// Line ~69 & ~480
context.go('/measurements/list/${widget.customerId}'); → 
context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': widget.customerId});
```

#### **edit_measurement_screen.dart**
```dart
// Line ~88 & ~366 & ~454
context.go('/measurements/list/${_measurement?.customerId}'); → 
context.goNamed(RouteNames.measurementList, pathParameters: {'customerId': _measurement!.customerId});

// Line ~290
context.go('/measurements'); → context.goNamed(RouteNames.measurementList, pathParameters: {...});
```

#### **measurement_list_screen.dart** (Already partially done)
```dart
// Line ~565
context.go('/measurements/category/${widget.customerId}'); → 
context.goNamed(RouteNames.measurementCategory, pathParameters: {'customerId': widget.customerId});
```

#### **measurement_category_screen.dart** (Already partially done)
```dart
// Line ~439
context.go('/measurements/add/${widget.customerId}?dressType=$dressType'); → 
context.goNamed(
  RouteNames.addMeasurement,
  pathParameters: {'customerId': widget.customerId},
  queryParameters: {'dressType': dressType},
);
```

---

### **5. Other Screens**

#### **home_screen.dart**
```dart
// Line ~355 & ~425
context.go('/privacy-policy'); → context.goNamed(RouteNames.privacyPolicy);
```

#### **get_started_screen.dart**
```dart
// Line ~98
context.go('/privacy-policy'); → context.goNamed(RouteNames.privacyPolicy);
```

#### **privacy_policy_screen.dart**
```dart
// Line ~41 & ~278
context.go('/auth/sign-in'); → context.goNamed(RouteNames.signIn);
```

#### **splash_screen_manager.dart**
```dart
// Line ~367
context.go('/dashboard'); → context.goNamed(RouteNames.dashboard);

// Line ~379
context.go('/auth/sign-in'); → context.goNamed(RouteNames.signIn);

// Line ~388
context.go('/home'); → context.goNamed(RouteNames.home);

// Line ~393 & ~404 & ~416
context.go('/privacy-policy'); → context.goNamed(RouteNames.privacyPolicy);
```

#### **settings_screen.dart** (Partially done)
```dart
// Line ~592
context.go('/auth/sign-in'); → context.goNamed(RouteNames.signIn);
```

---

### **6. Services**

#### **navigation_service.dart**
```dart
// These use dynamic routes, may need special handling
context.go(route); → // Keep as is or refactor to use route names
context.push(route); → // Keep as is or refactor to use route names
```

---

## 🎯 **Automated Migration Steps**

### **Step 1: Add Import to All Navigation Files**
Add this import to every file that uses navigation:
```dart
import 'package:tailer_app/routes/app_routes.dart';
```

### **Step 2: Replace Simple Routes**
Find and replace across all files:
- `context.go('/dashboard')` → `context.goNamed(RouteNames.dashboard)`
- `context.go('/auth/sign-in')` → `context.goNamed(RouteNames.signIn)`
- `context.go('/settings')` → `context.goNamed(RouteNames.settings)`
- `context.go('/customers')` → `context.goNamed(RouteNames.customers)`
- `context.go('/privacy-policy')` → `context.goNamed(RouteNames.privacyPolicy)`

### **Step 3: Replace Routes with Parameters**
Pattern: `context.go('/path/${variable}')` → `context.goNamed(RouteName, pathParameters: {'param': variable})`

### **Step 4: Replace Push Routes**
- `context.push('/route')` → `context.pushNamed(RouteNames.routeName)`
- `context.push('/route', extra: {...})` → `context.pushNamed(RouteNames.routeName, extra: {...})`

---

## ✅ **Testing Checklist**

After migration, test:
- [ ] Auth flow (sign in, sign up, forgot password, OTP)
- [ ] Dashboard navigation
- [ ] Customer CRUD operations
- [ ] Measurement CRUD operations
- [ ] Settings and logout
- [ ] Deep links with parameters
- [ ] Back navigation
- [ ] Bottom navigation bar

---

## 📚 **Files That Need Updates**

### **High Priority (Main Navigation)**
1. ✅ signin_screen.dart (Partially done)
2. ⏳ signup_screen.dart
3. ⏳ forgot_password_screen.dart
4. ⏳ password_reset.dart
5. ⏳ customer_profile_screen.dart
6. ⏳ add_customer_screen.dart
7. ⏳ view_customers_screen.dart
8. ⏳ customer_details_screen.dart
9. ⏳ edit_customer_screen.dart
10. ⏳ add_measurement_screen.dart
11. ⏳ edit_measurement_screen.dart
12. ⏳ splash_screen_manager.dart

### **Medium Priority (Secondary Navigation)**
13. ⏳ home_screen.dart
14. ⏳ privacy_policy_screen.dart
15. ⏳ get_started_screen.dart
16. ⏳ AuthGoogleButton.dart
17. ⏳ AuthFooter.dart

### **Low Priority (Edge Cases)**
18. ⏳ navigation_service.dart (May need refactoring)
19. ⏳ debug_navigation.dart

---

## 🚀 **Quick Start Command**

For VS Code, use Find & Replace with Regex:

**Find:** `context\.go\('(/[^']+)'\)`  
**Replace:** `context.goNamed(RouteNames.___)` (manual replacement needed)

---

**Ready to migrate? Start with auth screens, then customers, then measurements!**
