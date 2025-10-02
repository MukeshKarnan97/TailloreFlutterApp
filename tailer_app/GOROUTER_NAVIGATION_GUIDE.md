# GoRouter Navigation Guide

## 📋 **All Available Routes**

| Route Name              | Path                              | Parameters                      | Usage Example                                                      |
|-------------------------|-----------------------------------|---------------------------------|--------------------------------------------------------------------|
| `splash`                | `/splash`                         | -                               | `context.goNamed(RouteNames.splash)`                              |
| `onBoarding`            | `/auth/on-boarding`               | -                               | `context.goNamed(RouteNames.onBoarding)`                          |
| `signIn`                | `/auth/sign-in`                   | -                               | `context.goNamed(RouteNames.signIn)`                              |
| `signUp`                | `/auth/sign-up`                   | -                               | `context.goNamed(RouteNames.signUp)`                              |
| `forgotPassword`        | `/auth/forgot_password`           | -                               | `context.goNamed(RouteNames.forgotPassword)`                      |
| `otp`                   | `/auth/otp`                       | extra (Map)                     | `context.goNamed(RouteNames.otp, extra: {...})`                   |
| `passwordReset`         | `/auth/password-reset`            | extra (Map)                     | `context.goNamed(RouteNames.passwordReset, extra: {...})`         |
| `getStarted`            | `/get-started`                    | -                               | `context.goNamed(RouteNames.getStarted)`                          |
| `privacyPolicy`         | `/privacy-policy`                 | -                               | `context.goNamed(RouteNames.privacyPolicy)`                       |
| `home`                  | `/home`                           | -                               | `context.goNamed(RouteNames.home)`                                |
| `dashboard`             | `/dashboard`                      | -                               | `context.goNamed(RouteNames.dashboard)`                           |
| `customers`             | `/customers`                      | -                               | `context.goNamed(RouteNames.customers)`                           |
| `customerProfile`       | `/customers/profile`              | -                               | `context.goNamed(RouteNames.customerProfile)`                     |
| `addCustomer`           | `/customers/add`                  | -                               | `context.goNamed(RouteNames.addCustomer)`                         |
| `viewCustomers`         | `/customers/view`                 | -                               | `context.goNamed(RouteNames.viewCustomers)`                       |
| `customerDetails`       | `/customers/details/:customerId`  | customerId (path)               | `context.goNamed(RouteNames.customerDetails, pathParameters: {...})`|
| `editCustomer`          | `/customers/edit/:customerId`     | customerId (path)               | `context.goNamed(RouteNames.editCustomer, pathParameters: {...})`  |
| `measurementList`       | `/measurements/list/:customerId`  | customerId (path)               | `context.goNamed(RouteNames.measurementList, pathParameters: {...})`|
| `measurementCategory`   | `/measurements/category/:customerId`| customerId (path)             | `context.goNamed(RouteNames.measurementCategory, pathParameters: {...})`|
| `addMeasurement`        | `/measurements/add/:customerId`   | customerId (path), dressType (query)| `context.goNamed(RouteNames.addMeasurement, pathParameters: {...}, queryParameters: {...})`|
| `editMeasurement`       | `/measurements/edit/:measurementId`| measurementId (path)           | `context.goNamed(RouteNames.editMeasurement, pathParameters: {...})`|
| `settings`              | `/settings`                       | -                               | `context.goNamed(RouteNames.settings)`                            |

---

## 🚀 **How to Navigate**

### **1. Simple Navigation (No Parameters)**

```dart
// Navigate to dashboard
context.goNamed(RouteNames.dashboard);

// Navigate to settings
context.goNamed(RouteNames.settings);

// Navigate to customers
context.goNamed(RouteNames.customers);
```

### **2. Navigation with Path Parameters**

```dart
// Navigate to customer details
context.goNamed(
  RouteNames.customerDetails,
  pathParameters: {'customerId': customer.uniqueId},
);

// Navigate to edit customer
context.goNamed(
  RouteNames.editCustomer,
  pathParameters: {'customerId': '123'},
);

// Navigate to measurement list
context.goNamed(
  RouteNames.measurementList,
  pathParameters: {'customerId': customer.uniqueId},
);
```

### **3. Navigation with Query Parameters**

```dart
// Navigate to add measurement with dress type
context.goNamed(
  RouteNames.addMeasurement,
  pathParameters: {'customerId': customer.uniqueId},
  queryParameters: {'dressType': 'shirt'},
);
```

### **4. Navigation with Extra Data**

```dart
// Navigate to OTP screen with extra data
context.goNamed(
  RouteNames.otp,
  extra: {
    'firstTitle': 'Verify',
    'secondTitle': 'OTP',
    'emailText': 'Enter the OTP sent to',
    'email': 'user@example.com',
    'onVerified': () {
      // Callback after verification
    },
  },
);

// Navigate to password reset
context.goNamed(
  RouteNames.passwordReset,
  extra: {'email': 'user@example.com'},
);
```

### **5. Push (Keep Previous Screen in Stack)**

```dart
// Push a new screen (can go back)
context.pushNamed(RouteNames.customerDetails, pathParameters: {'customerId': '123'});
```

### **6. Go (Replace Current Screen)**

```dart
// Replace current screen
context.goNamed(RouteNames.dashboard);
```

### **7. Replace (Remove Previous Route)**

```dart
// Replace and remove previous route
context.replaceNamed(RouteNames.signIn);
```

---

## 📱 **Common Navigation Patterns**

### **From Dashboard to Customer Details**

```dart
// In dashboard_screen.dart or customer card
onTap: () {
  context.goNamed(
    RouteNames.customerDetails,
    pathParameters: {'customerId': customer.uniqueId},
  );
}
```

### **From Customer Details to Edit**

```dart
// In customer_details_screen.dart
onPressed: () {
  context.goNamed(
    RouteNames.editCustomer,
    pathParameters: {'customerId': widget.customerId},
  );
}
```

### **From Customer Details to Measurements**

```dart
// In customer_details_screen.dart
onPressed: () {
  context.goNamed(
    RouteNames.measurementList,
    pathParameters: {'customerId': widget.customerId},
  );
}
```

### **From Measurement Category to Add Measurement**

```dart
// In measurement_category_screen.dart
onTap: (dressType) {
  context.goNamed(
    RouteNames.addMeasurement,
    pathParameters: {'customerId': widget.customerId},
    queryParameters: {'dressType': dressType},
  );
}
```

### **Logout and Go to Sign In**

```dart
// In profile dropdown or settings
onPressed: () async {
  await authService.signOut();
  if (context.mounted) {
    context.goNamed(RouteNames.signIn);
  }
}
```

---

## ⚠️ **Important Notes**

1. **Always import RouteNames**: `import 'package:tailer_app/routes/app_routes.dart';`
2. **Use `context.mounted` check** before navigation after async operations
3. **Use `goNamed` for replacement**, `pushNamed` for stacking
4. **Path parameters are required**, query parameters are optional
5. **Extra data** is good for passing complex objects or callbacks

---

## 🔄 **Migration from Old Navigation**

### **❌ OLD WAY**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CustomerDetailsScreen(customerId: '123'),
  ),
);

// OR
context.go('/customers/details/123');
```

### **✅ NEW WAY**
```dart
context.goNamed(
  RouteNames.customerDetails,
  pathParameters: {'customerId': '123'},
);
```

---

## 🎯 **Benefits of Named Routes**

- ✅ **Type-safe**: Autocomplete and compile-time checking
- ✅ **Maintainable**: Change path in one place
- ✅ **Readable**: Clear intent with route names
- ✅ **Refactorable**: Easy to find all usages
- ✅ **Consistent**: Same pattern everywhere

---

## 📚 **Quick Reference**

```dart
// Import
import 'package:tailer_app/routes/app_routes.dart';

// Simple
context.goNamed(RouteNames.dashboard);

// With params
context.goNamed(
  RouteNames.customerDetails,
  pathParameters: {'customerId': id},
);

// With query
context.goNamed(
  RouteNames.addMeasurement,
  pathParameters: {'customerId': id},
  queryParameters: {'dressType': type},
);

// With extra
context.goNamed(
  RouteNames.otp,
  extra: {'email': email, 'onVerified': callback},
);
```

---

**Start using GoRouter named routes everywhere for cleaner, more maintainable navigation! 🚀**
