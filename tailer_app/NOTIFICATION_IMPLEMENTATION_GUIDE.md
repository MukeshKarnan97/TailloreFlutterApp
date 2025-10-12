# 🔔 Complete Notification System Implementation Guide

## Overview
This document covers the comprehensive notification system for the Tailor App, including **local notifications**, **push notifications**, **scheduled reminders**, and **notification actions**.

---

## 📦 Packages Added

```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^18.0.1  # Local system notifications
  firebase_core: ^3.8.1                 # Firebase base (optional for push)
  firebase_messaging: ^15.1.5           # Push notifications (optional)
  timezone: ^0.9.4                      # Scheduled notifications
  permission_handler: ^11.3.1           # Notification permissions
```

---

## 🏗️ Architecture

### Two-Layer Notification System

1. **NotificationService** (`lib/data/services/notification_service.dart`)
   - Manages in-app notification database
   - Stores notification history
   - Provides UI notification list
   - Handles unread count badges

2. **NotificationManager** (`lib/data/services/notification_manager.dart`)
   - Manages system notifications
   - Handles local notifications (flutter_local_notifications)
   - Schedules future notifications
   - Manages notification channels
   - Handles notification permissions

---

## 🚀 Features Implemented

### ✅ Instant Notifications
- Order status changes
- Payment received
- Order delivered
- Order cancelled
- Order overdue

### ✅ Scheduled Notifications
- **Delivery Reminders**: 1 day before delivery at 10 AM
- **Payment Reminders**: 2 days before delivery at 3 PM
- Custom reminder scheduling

### ✅ Notification Channels (Android)
1. **Orders Channel**: Order status updates, deliveries
2. **Payments Channel**: Payment updates and reminders
3. **Reminders Channel**: Delivery and payment reminders
4. **General Channel**: Other notifications

### ✅ Notification Actions
- Tap to navigate to order details
- Swipe to dismiss
- Mark as read
- Deep linking support

---

## 🔧 Configuration Required

### 1. Android Configuration

#### Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application
        android:label="Tailor App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add notification receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
        
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
            
        <!-- Rest of your manifest -->
    </application>
</manifest>
```

#### Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34  // Must be 33+
    
    defaultConfig {
        minSdkVersion 21  // Minimum 21
        targetSdkVersion 34
    }
}
```

### 2. iOS Configuration

#### Update `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 📝 Usage Examples

### 1. Initialize Notification System

```dart
// In main.dart or app initialization
import 'package:tailer_app/data/services/notification_service.dart';
import 'package:go_router/go_router.dart';

Future<void> initializeNotifications(GoRouter router) async {
  final notificationService = NotificationService();
  
  await notificationService.initialize(
    onNotificationTap: (payload) {
      if (payload != null) {
        final data = jsonDecode(payload);
        final orderId = data['orderId'];
        if (orderId != null) {
          router.push('/orders/detail?id=$orderId');
        }
      }
    },
  );
}
```

### 2. Show Instant Notifications

```dart
// When order status changes
final notificationService = NotificationService();
await notificationService.notifyOrderStatusUpdate(order, 'pending', 'in_progress');

// When payment is received
await notificationService.notifyPaymentReceived(order, 1000.0);

// When order is delivered
await notificationService.notifyOrderDelivered(order);

// When order is cancelled
await notificationService.notifyOrderCancellation(order, cancellation);

// When order is overdue
await notificationService.notifyOrderOverdue(order);
```

### 3. Schedule Reminder Notifications

```dart
final notificationService = NotificationService();

// Schedule delivery reminder (1 day before at 10 AM)
await notificationService.scheduleDeliveryReminder(order);

// Schedule payment reminder (2 days before at 3 PM)
await notificationService.schedulePaymentReminder(order);

// Custom days before delivery
await notificationService.schedulePaymentReminder(order, daysBeforeDelivery: 3);
```

### 4. Cancel Scheduled Reminders

```dart
// Cancel all reminders for an order (when order is cancelled/completed)
await notificationService.cancelOrderReminders(orderId);
```

### 5. Display Notification List in UI

```dart
import 'package:tailer_app/features/notifications/widgets/notification_list_widget.dart';

// In your screen
NotificationListWidget(
  showOnlyUnread: false,  // Show all notifications
  maxItems: 20,           // Limit to 20 items
)
```

### 6. Show Notification Badge

```dart
import 'package:tailer_app/features/notifications/widgets/notification_list_widget.dart';
import 'package:tailer_app/data/services/notification_service.dart';

// In AppBar
AppBar(
  actions: [
    NotificationBadge(
      notificationService: _notificationService,
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: _showNotificationsModal,
      ),
    ),
  ],
)
```

---

## 🔗 Integration Points

### 1. Order Creation/Update

```dart
// lib/features/orders/screens/order_detail_screen.dart
// When saving order with delivery date
if (order.deliveryDate.isAfter(DateTime.now())) {
  // Schedule reminders
  await _notificationService.scheduleDeliveryReminder(order);
  await _notificationService.schedulePaymentReminder(order);
}
```

### 2. Status Change

```dart
// When order status changes
Future<void> updateOrderStatus(Order order, String newStatus) async {
  final oldStatus = order.status;
  
  // Update order in database
  await _dbService.updateOrder(order.copyWith(status: newStatus));
  
  // Send notification
  await _notificationService.notifyOrderStatusUpdate(order, oldStatus, newStatus);
  
  // If delivered, cancel pending reminders
  if (newStatus == 'delivered') {
    await _notificationService.cancelOrderReminders(order.uniqueId);
    await _notificationService.notifyOrderDelivered(order);
  }
}
```

### 3. Payment Recording

```dart
// When payment is recorded
Future<void> recordPayment(Order order, double amount) async {
  // Save payment to database
  await _dbService.addPayment(payment);
  
  // Update order
  final updatedOrder = order.copyWith(
    advancePaid: order.advancePaid + amount,
  );
  await _dbService.updateOrder(updatedOrder);
  
  // Send notification
  await _notificationService.notifyPaymentReceived(updatedOrder, amount);
  
  // If fully paid, cancel payment reminders
  if (updatedOrder.advancePaid >= updatedOrder.totalAmount) {
    final notificationManager = NotificationManager();
    final paymentReminderId = '${order.uniqueId}-payment'.hashCode.abs();
    await notificationManager.cancelNotification(paymentReminderId);
  }
}
```

### 4. Order Cancellation

```dart
// When order is cancelled
Future<void> cancelOrder(Order order, OrderCancellation cancellation) async {
  // Save cancellation
  await _dbService.insertOrderCancellation(cancellation);
  
  // Update order status
  await _dbService.updateOrder(order.copyWith(status: 'cancelled'));
  
  // Cancel all scheduled reminders
  await _notificationService.cancelOrderReminders(order.uniqueId);
  
  // Send cancellation notification
  await _notificationService.notifyOrderCancellation(order, cancellation);
}
```

### 5. Overdue Order Detection

```dart
// Run daily check for overdue orders
Future<void> checkOverdueOrders() async {
  final now = DateTime.now();
  final orders = await _dbService.getOrders();
  
  for (final order in orders) {
    if (order.deliveryDate.isBefore(now) && 
        order.status != 'delivered' && 
        order.status != 'cancelled') {
      // Send overdue notification
      await _notificationService.notifyOrderOverdue(order);
    }
  }
}
```

---

## 🎨 UI Components

### 1. Notification Modal Bottom Sheet

```dart
void _showNotificationsModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                  },
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notification list
          Expanded(
            child: NotificationListWidget(),
          ),
        ],
      ),
    ),
  );
}
```

### 2. Notification Badge

```dart
// Already implemented in notification_list_widget.dart
NotificationBadge(
  notificationService: _notificationService,
  child: IconButton(
    icon: const Icon(Icons.notifications_outlined),
    onPressed: _showNotificationsModal,
  ),
)
```

---

## 🧪 Testing Guide

### 1. Test Instant Notifications

```dart
// Test order status notification
final testOrder = Order(...);
await notificationService.notifyOrderStatusUpdate(
  testOrder, 
  'pending', 
  'in_progress'
);

// Check: System notification should appear
// Check: In-app notification should be added to list
```

### 2. Test Scheduled Notifications

```dart
// Create order with delivery date 2 days from now
final futureOrder = Order(
  deliveryDate: DateTime.now().add(Duration(days: 2)),
  // ... other fields
);

// Schedule reminders
await notificationService.scheduleDeliveryReminder(futureOrder);
await notificationService.schedulePaymentReminder(futureOrder);

// Check: Notifications should be scheduled
// Wait until scheduled time to verify they appear
```

### 3. Test Permission Handling

```dart
final notificationManager = NotificationManager();
final hasPermission = await notificationManager.areNotificationsEnabled();

if (!hasPermission) {
  // Show permission dialog
  await notificationManager.openNotificationSettings();
}
```

### 4. Test Notification Tap Actions

```dart
// Tap on notification
// Should navigate to order detail screen
// Payload should contain order ID
```

---

## 📋 Notification Types & Behavior

| Type | Trigger | Channel | Priority | Sound | Vibration | When Scheduled |
|------|---------|---------|----------|-------|-----------|----------------|
| Order Status Update | Manual | Orders | High | ✅ | ✅ | Instant |
| Payment Received | Manual | Payments | High | ✅ | ✅ | Instant |
| Order Delivered | Manual | Orders | High | ✅ | ✅ | Instant |
| Order Cancelled | Manual | Orders | High | ✅ | ✅ | Instant |
| Order Overdue | Auto/Manual | Orders | High | ✅ | ✅ | Instant |
| Delivery Reminder | Auto | Reminders | Default | ✅ | ✅ | 1 day before @ 10 AM |
| Payment Reminder | Auto | Reminders | Default | ✅ | ✅ | 2 days before @ 3 PM |

---

## 🔐 Permissions

### Android 13+ (API 33+)
- Requires `POST_NOTIFICATIONS` permission
- Automatically requested on first notification
- User can deny (handled gracefully)

### iOS
- Requires user approval
- Alert, Badge, Sound permissions
- Requested automatically on first notification

---

## 🐛 Troubleshooting

### Notifications Not Showing

**1. Check Permissions:**
```dart
final enabled = await notificationManager.areNotificationsEnabled();
if (!enabled) {
  await notificationManager.openNotificationSettings();
}
```

**2. Check Android Manifest:**
- Verify all permissions are added
- Verify receivers are registered

**3. Check Notification Channels:**
- Ensure channels are created
- Check channel importance level

**4. Check Scheduled Time:**
```dart
// Ensure scheduled time is in the future
if (scheduledTime.isAfter(DateTime.now())) {
  // Will be scheduled
} else {
  // Time has passed, won't schedule
}
```

### Notifications Not Navigating

**1. Check Payload:**
```dart
// Payload must be valid JSON
final payload = jsonEncode({
  'type': 'order_status',
  'orderId': order.uniqueId,
});
```

**2. Check Navigation Handler:**
```dart
// Ensure handler is registered in initialize()
await notificationService.initialize(
  onNotificationTap: (payload) {
    // Handle navigation
  },
);
```

---

## 🚀 Future Enhancements

### Push Notifications (Firebase Cloud Messaging)
```dart
// Optional: Add push notification support
// Requires Firebase project setup
// See Firebase documentation for integration
```

### Notification Groups
```dart
// Group related notifications
// E.g., all order updates for a customer
```

### Custom Sounds
```dart
// Add custom notification sounds
// Place sounds in android/app/src/main/res/raw/
```

### Rich Notifications
```dart
// Add images, actions buttons
// Expandable notifications with more details
```

---

## 📚 Additional Resources

- [flutter_local_notifications Docs](https://pub.dev/packages/flutter_local_notifications)
- [timezone Package](https://pub.dev/packages/timezone)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [iOS User Notifications](https://developer.apple.com/documentation/usernotifications)

---

## ✅ Implementation Checklist

- [x] Add notification packages to pubspec.yaml
- [x] Create NotificationManager service
- [x] Integrate with NotificationService
- [x] Configure Android manifest
- [ ] Configure iOS permissions
- [ ] Test instant notifications
- [ ] Test scheduled notifications
- [ ] Test notification tap actions
- [ ] Integrate with order creation flow
- [ ] Integrate with status change flow
- [ ] Integrate with payment flow
- [ ] Integrate with cancellation flow
- [ ] Add overdue order checking
- [ ] Create notification settings screen
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Update user documentation

---

**Last Updated:** October 12, 2025
**Version:** 1.0.0
**Status:** Ready for Integration
