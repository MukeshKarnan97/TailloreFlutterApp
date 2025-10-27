# Missing Translation Keys - Hardcoded English Text

This document lists all hardcoded English text found in the app that needs to be added to the translation system.

## 🔴 Critical UI Elements (User-Facing)

### Bottom Navigation (widgets/custom_bottom_navigation.dart)
- Line 303: `'Dashboard'`
- Line 308: `'Customers'`
- Line 313: `'Orders'`
- Line 318: `'Settings'`

**Suggested Translation Keys:**
```dart
'dashboard': 'Dashboard',
'customers': 'Customers',
'orders': 'Orders',
'settings': 'Settings',
```

---

### Order Cancellation Dialog (features/orders/widgets/order_cancellation_dialog.dart)
- Line 122: `'Cancel Order'`
- Line 194: `'Please specify the reason for cancellation'`
- Line 210: `'Refund Required'`
- Line 211: `'Check if customer paid and needs refund'`
- Line 250: `'Additional notes about the refund'`
- Line 285: `'Cancel'`
- Line 299: `'Cancel Order'`

**Suggested Translation Keys:**
```dart
'cancelOrder': 'Cancel Order',
'pleaseSpecifyReason': 'Please specify the reason for cancellation',
'refundRequired': 'Refund Required',
'checkIfCustomerPaid': 'Check if customer paid and needs refund',
'additionalRefundNotes': 'Additional notes about the refund',
'cancel': 'Cancel',
```

---

### Pending Orders Screen (features/orders/screens/pending_orders_screen.dart)
- Line 523: `'No orders found for "${_searchController.text}"'`
- Line 524: `'No pending orders found'`
- Line 551: `'Clear Search'`

**Suggested Translation Keys:**
```dart
'noOrdersFoundFor': 'No orders found for',
'noPendingOrdersFound': 'No pending orders found',
'clearSearch': 'Clear Search',
```

---

### Ready Orders Screen (features/orders/screens/ready_orders_screen.dart)
- Line 683: `'Mark as Delivered'`
- Line 684: `'Are you sure you want to mark this order as delivered?'`
- Line 688: `'Cancel'`
- Line 692: `'Confirm'`
- Line 707: `'Order marked as delivered successfully'`
- Line 716: `'Failed to update order status'`

**Suggested Translation Keys:**
```dart
'markAsDelivered': 'Mark as Delivered',
'confirmMarkAsDelivered': 'Are you sure you want to mark this order as delivered?',
'confirm': 'Confirm',
'orderMarkedAsDelivered': 'Order marked as delivered successfully',
'failedToUpdateOrderStatus': 'Failed to update order status',
```

---

### In Progress Orders Screen (features/orders/screens/in_progress_orders_screen.dart)
- Line 733: `'Update Order Status'`
- Line 738: `'Cutting'`
- Line 742: `'Stitching'`
- Line 746: `'Ready for Delivery'`
- Line 754: `'Cancel'`
- Line 769: `'Order status updated successfully'`
- Line 778: `'Failed to update order status'`

**Suggested Translation Keys:**
```dart
'updateOrderStatus': 'Update Order Status',
'cutting': 'Cutting',
'stitching': 'Stitching',
'readyForDelivery': 'Ready for Delivery',
'orderStatusUpdated': 'Order status updated successfully',
```

---

### Order Detail Screen (features/orders/screens/order_detail_screen.dart)
- Line 134: `'Failed to update order status'`
- Line 287: `'Notifications'`
- Line 1572: `'Max: ₹${remainingAmount.toStringAsFixed(0)}'`
- Line 1611: `'Transaction reference, etc.'`
- Line 1754: `'Failed to update payment'`
- Line 174: `'Update Order Status'`
- Line 212: `'Select New Status:'`
- Line 264: `'Update Status'`
- Line 1002: `'Update Order Status'`
- Line 1231: `'Delete Order'`
- Line 1243: `'Are you sure you want to delete this order?'`
- Line 1427: `'Please enter a valid amount'`
- Line 1440: `'Update Payment'`

**Suggested Translation Keys:**
```dart
'notifications': 'Notifications',
'maxAmount': 'Max',
'transactionReference': 'Transaction reference, etc.',
'failedToUpdatePayment': 'Failed to update payment',
'selectNewStatus': 'Select New Status:',
'updateStatus': 'Update Status',
'deleteOrder': 'Delete Order',
'confirmDeleteOrder': 'Are you sure you want to delete this order?',
'pleaseEnterValidAmount': 'Please enter a valid amount',
'updatePayment': 'Update Payment',
```

---

### Customer Selector Widget (features/orders/widgets/customer_selector.dart)
- Line 60: `'Select Customer'`
- Line 122: `'No customers found. Please add customers first.'`
- Line 207: `'Select Customer'`
- Line 225: `'Search by name, phone, or ID...'`
- Line 250: `'No customers available'`
- Line 251: `'No customers found matching "$_searchQuery"'`

**Suggested Translation Keys:**
```dart
'selectCustomer': 'Select Customer',
'noCustomersFoundPleaseAdd': 'No customers found. Please add customers first.',
'searchByNamePhoneId': 'Search by name, phone, or ID...',
'noCustomersAvailable': 'No customers available',
'noCustomersFoundMatching': 'No customers found matching',
```

---

### Add Order Screen (features/orders/screens/add_order_screen.dart)
- Line 249: `'Permission Required'`
- Line 258: `'Cancel'`
- Line 265: `'Open Settings'`

**Suggested Translation Keys:**
```dart
'permissionRequired': 'Permission Required',
'openSettings': 'Open Settings',
```

---

### Payment Collection Screen (features/payments/screens/payment_collection_screen.dart)
- Line 418: `'Search unpaid orders, customers...'`
- Line 419: `'Search active orders, customers...'`
- Line 522: `'NO PAYMENT'`
- Line 865: `'No Unpaid Orders'` / `'No Active Orders'`
- Line 876: `'No orders are currently in progress.\nAll orders are completed or delivered.'`
- Line 933: `'Please enter a valid amount'`
- Line 1107: `'Max: ₹${pendingAmount.toStringAsFixed(0)}'`
- Line 1164: `'Transaction reference, etc.'`

**Suggested Translation Keys:**
```dart
'searchUnpaidOrders': 'Search unpaid orders, customers...',
'searchActiveOrders': 'Search active orders, customers...',
'noPayment': 'NO PAYMENT',
'noUnpaidOrders': 'No Unpaid Orders',
'noActiveOrders': 'No Active Orders',
'noOrdersInProgress': 'No orders are currently in progress.\nAll orders are completed or delivered.',
```

---

### Payment History Screen (features/payments/screens/payment_history_screen.dart)
- Line 311: `'Search payments...'`
- Line 488: `'No Payments Found'`
- Line 498: `'No payments found for this order'`
- Line 499: `'No payment transactions found'`

**Suggested Translation Keys:**
```dart
'searchPayments': 'Search payments...',
'noPaymentsFound': 'No Payments Found',
'noPaymentsForThisOrder': 'No payments found for this order',
'noPaymentTransactions': 'No payment transactions found',
```

---

### Payment Reports Screen (features/settings/screens/payment_report/payment_reports_screen.dart)
- Line 245-248: Dropdown items: `'Today'`, `'This Week'`, `'This Month'`, `'This Year'`
- Line 293: `'No orders with payments found'`
- Line 383: `'No payments recorded'`
- Line 394: `'View Details'`
- Line 425: `'No analytics data available'`
- Line 568: `'No revenue data available'`
- Line 680: `'No payments recorded'`
- Line 698: `'Close'`
- Line 705: `'Generate PDF Report'`
- Line 735: `'PDF generation feature will be implemented soon'`

**Suggested Translation Keys:**
```dart
'today': 'Today',
'thisWeek': 'This Week',
'thisMonth': 'This Month',
'thisYear': 'This Year',
'noOrdersWithPayments': 'No orders with payments found',
'noPaymentsRecorded': 'No payments recorded',
'viewDetails': 'View Details',
'noAnalyticsData': 'No analytics data available',
'noRevenueData': 'No revenue data available',
'close': 'Close',
'generatePdfReport': 'Generate PDF Report',
'pdfGenerationComingSoon': 'PDF generation feature will be implemented soon',
```

---

### Receipt Management Screen (features/settings/screens/payment_report/receipt_management_screen.dart)
- Line 210: `'Create receipt feature coming soon'`
- Line 262: `'No payment receipts found'`
- Line 345: `'No order receipts found'`
- Line 683: `'Close'`
- Line 690: `'Generate PDF'`
- Line 755: `'Close'`
- Line 762: `'Generate PDF'`

**Suggested Translation Keys:**
```dart
'createReceiptComingSoon': 'Create receipt feature coming soon',
'noPaymentReceipts': 'No payment receipts found',
'noOrderReceipts': 'No order receipts found',
'generatePdf': 'Generate PDF',
```

---

### Refund Management Screen (features/settings/screens/payment_report/refund_management_screen.dart)
- Line 152: `'No refunds found'`
- Line 179: `'Add Refund'`
- Line 194: `'No reason provided'`
- Line 287: `'Reason'`, `'No reason provided'`
- Line 296: `'Close'`
- Line 304: `'Process'`
- Line 338: `'Create Refund'`
- Line 353: `'Refund Method'`
- Line 355-357: Dropdown: `'Cash'`, `'Card'`, `'Bank Transfer'`
- Line 376: `'Cancel'`
- Line 387: `'Create'`
- Line 409: `'Refund created successfully'`
- Line 439: `'Refund processed successfully'`

**Suggested Translation Keys:**
```dart
'noRefundsFound': 'No refunds found',
'addRefund': 'Add Refund',
'noReasonProvided': 'No reason provided',
'reason': 'Reason',
'process': 'Process',
'createRefund': 'Create Refund',
'refundMethod': 'Refund Method',
'cash': 'Cash',
'card': 'Card',
'bankTransfer': 'Bank Transfer',
'create': 'Create',
'refundCreatedSuccessfully': 'Refund created successfully',
'refundProcessedSuccessfully': 'Refund processed successfully',
```

---

### Edit Profile Screen (features/settings/screens/profile/edit_profile_screen.dart)
- Line 232: `'Please grant storage permission to select photos'`
- Line 244: `'Permission Required'`
- Line 249: `'Cancel'`
- Line 256: `'Open Settings'`
- Line 306: `'Please grant camera permission to take photos'`
- Line 318: `'Permission Required'`
- Line 323: `'Cancel'`
- Line 330: `'Open Settings'`

**Suggested Translation Keys:**
```dart
'grantStoragePermission': 'Please grant storage permission to select photos',
'grantCameraPermission': 'Please grant camera permission to take photos',
```

---

### Order Measurement Form Widget (features/orders/widgets/order_measurement_form.dart)
- Line 231: `'Select a dress type to enter measurements'`
- Line 279: `'No measurements required for this dress type'`
- Line 344: `'Please enter ${_formatMeasurementName(entry.key).toLowerCase()}'`
- Line 348: `'Please enter a valid measurement'`

**Suggested Translation Keys:**
```dart
'selectDressTypeToEnterMeasurements': 'Select a dress type to enter measurements',
'noMeasurementsRequired': 'No measurements required for this dress type',
'pleaseEnterMeasurement': 'Please enter',
'pleaseEnterValidMeasurement': 'Please enter a valid measurement',
```

---

### Dress Type Selector Widget (features/orders/widgets/dress_type_selector.dart)
- Line 54: `'Select dress type'`

**Suggested Translation Keys:**
```dart
'selectDressType': 'Select dress type',
```

---

### Settings Screen (features/settings/screens/settings_screen.dart)
- Line 251: `'View payment analytics and reports'`
- Line 409: `'View third-party licenses'`

**Suggested Translation Keys:**
```dart
'viewPaymentAnalytics': 'View payment analytics and reports',
'viewThirdPartyLicenses': 'View third-party licenses',
```

---

### Privacy Policy Screen (features/privacy/privacy_policy_screen.dart)
- Line 69: `'Privacy Policy Required'`
- Line 80: `'OK'`
- Line 143: `'Please read and accept our privacy policy to continue'`

**Suggested Translation Keys:**
```dart
'privacyPolicyRequired': 'Privacy Policy Required',
'ok': 'OK',
'pleaseReadPrivacyPolicy': 'Please read and accept our privacy policy to continue',
```

---

### Privacy Policy Viewer Screen (features/settings/screens/legal/privacy_policy_viewer_screen.dart)
- Line 156: `'Please read this privacy policy carefully...'`
- Line 248: `'No third-party advertising cookies are used.'`

**Suggested Translation Keys:**
```dart
'readPrivacyPolicyCarefully': 'Please read this privacy policy carefully to understand how we collect, use, and protect your personal information.',
'noThirdPartyAdvertising': 'No third-party advertising cookies are used.',
```

---

### User Agreement Screen (features/onboarding/user_agreement_screen.dart)
- Line 92: `'Terms Required'`
- Line 103: `'OK'`
- Line 169: `'Please read them carefully before proceeding.'`
- Line 252: `'Please scroll down to read the complete agreement'`

**Suggested Translation Keys:**
```dart
'termsRequired': 'Terms Required',
'pleaseReadCarefully': 'Please read them carefully before proceeding.',
'pleaseScrollDown': 'Please scroll down to read the complete agreement',
```

---

### App Info Screen (features/settings/screens/about/app_info_screen.dart)
- Line 376: `'View open source licenses'`

**Suggested Translation Keys:**
```dart
'viewOpenSourceLicenses': 'View open source licenses',
```

---

### Feedback Screen (features/settings/screens/support/feedback_screen.dart)
- Line 746: `'Please provide a rating'`

**Suggested Translation Keys:**
```dart
'pleaseProvideRating': 'Please provide a rating',
```

---

### Home Screen (features/home/home_screen.dart)
- Line 98: `'Mark All Read'`
- Line 208: `'Exit App'`
- Line 213: `'Cancel'`
- Line 217: `'Exit'`

**Suggested Translation Keys:**
```dart
'markAllRead': 'Mark All Read',
'exitApp': 'Exit App',
'exit': 'Exit',
```

---

### Dashboard Screen (features/dashboard/screens/dashboard_screen.dart)
- Line 181: `'Dashboard updated with latest data'`
- Line 218: `'Back button pressed'`
- Line 493-497: Dropdown: `'Today'`, `'This Week'`, `'This Month'`, `'This Year'`, `'All Time'`

**Suggested Translation Keys:**
```dart
'dashboardUpdated': 'Dashboard updated with latest data',
'backButtonPressed': 'Back button pressed',
'allTime': 'All Time',
```

---

### Welcome Screen (features/auth/screens/welcome_screen.dart)
- Line 183: `'Skip'`

**Suggested Translation Keys:**
```dart
'skip': 'Skip',
```

---

### Measurement Form Widget (features/measurements/widgets/measurement_form.dart)
- Line 322: `'Enter ${measurementDetails?['name'] ?? category}'`

**Suggested Translation Keys:**
```dart
'enter': 'Enter',
```

---

### Order Payment History Screen (features/payments/screens/order_payment_history_screen.dart)
- Line 156: `'No payment data available to generate PDF'`

**Suggested Translation Keys:**
```dart
'noPaymentDataForPdf': 'No payment data available to generate PDF',
```

---

### Database Viewer Screen (features/debug/database_viewer_screen.dart)
- Line 13: `'Debug Reset'`
- Line 80: `'Database Viewer'`
- Line 141: `'Retry'`
- Line 490: `'Password Test'`
- Line 547: `'Close'`

**Suggested Translation Keys:**
```dart
'debugReset': 'Debug Reset',
'databaseViewer': 'Database Viewer',
'retry': 'Retry',
'passwordTest': 'Password Test',
```

---

### Demo Screen (features/demo/simple_language_demo_screen.dart)
- Line 247: `'Enter customer name'`
- Line 256: `'Enter phone number'`

**Suggested Translation Keys:**
```dart
'enterCustomerName': 'Enter customer name',
'enterPhoneNumber': 'Enter phone number',
```

---

### Quick DB Check Button Widget (widgets/quick_db_check_button.dart)
- Line 35: `'Check DB'`

**Suggested Translation Keys:**
```dart
'checkDb': 'Check DB',
```

---

### Orders Main Screen (features/orders/screens/orders_main_screen.dart)
- Line 1091: `'No deleted orders found'`

**Suggested Translation Keys:**
```dart
'noDeletedOrders': 'No deleted orders found',
```

---

## 📊 Summary

**Total Hardcoded Strings Found:** ~150+

**Categories:**
1. **Navigation & UI Elements:** ~10
2. **Order Management:** ~60
3. **Payment & Financial:** ~30
4. **Customer Management:** ~15
5. **Settings & Profile:** ~20
6. **Messages & Notifications:** ~15
7. **General Actions:** ~10

## ✅ Action Items

1. **Add all missing translation keys to:**
   - `lib/core/translations/locales/en_translations.dart`
   - `lib/core/translations/locales/ta_translations.dart`
   - `lib/core/translations/locales/hi_translations.dart`

2. **Update all UI files to use translation keys** instead of hardcoded strings

3. **Pattern to follow:**
   ```dart
   // Before (Hardcoded)
   Text('Cancel Order')
   
   // After (Translated)
   Text(AppLocalizations.of(context).t('cancelOrder'))
   ```

## 🔍 How to Find More

Run these searches in your codebase:
```bash
# Find Text widgets with hardcoded strings
grep -r "Text\('[A-Z]" lib/

# Find hardcoded labels
grep -r "label:\s*['\"]" lib/

# Find hardcoded hints
grep -r "hintText:\s*['\"]" lib/
```

---

**Generated on:** October 27, 2025
**App Version:** Based on current codebase analysis
