# 🚀 Notification Integration Quick Start

## Step 1: Install Dependencies

```bash
flutter pub get
```

## Step 2: Update Android Build Configuration

Check `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34  // Must be 33 or higher
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

## Step 3: Initialize in Main App

Update `lib/main.dart`:

```dart
import 'package:tailer_app/data/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service early
  final notificationService = NotificationService();
  
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;
  
  const MyApp({Key? key, required this.notificationService}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  
  @override
  void initState() {
    super.initState();
    _setupRouter();
    _initializeNotifications();
  }
  
  void _setupRouter() {
    // Your existing router setup
    _router = GoRouter(
      routes: [
        // Your routes
      ],
    );
  }
  
  Future<void> _initializeNotifications() async {
    await widget.notificationService.initialize(
      onNotificationTap: (payload) {
        if (payload != null) {
          try {
            final data = jsonDecode(payload);
            final orderId = data['orderId'];
            
            if (orderId != null) {
              _router.push('/orders/detail?id=$orderId');
            }
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Tailor App',
      // Rest of your app config
    );
  }
}
```

## Step 4: Add to Order Creation/Edit Screen

```dart
// lib/features/orders/screens/add_order_screen.dart
import 'package:tailer_app/data/services/notification_service.dart';

class AddOrderScreen extends StatefulWidget {
  // ... existing code
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final NotificationService _notificationService = NotificationService();
  
  Future<void> _saveOrder() async {
    // Your existing save logic
    final order = Order(
      // ... order details
      deliveryDate: _selectedDeliveryDate,
    );
    
    await _dbService.insertOrder(order);
    
    // 🎯 NEW: Schedule reminder notifications
    if (order.deliveryDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleDeliveryReminder(order);
      await _notificationService.schedulePaymentReminder(order);
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order created successfully!')),
    );
    
    Navigator.pop(context);
  }
}
```

## Step 5: Add to Order Status Update

```dart
// lib/features/orders/screens/order_detail_screen.dart
Future<void> _updateOrderStatus(String newStatus) async {
  final oldStatus = _order.status;
  
  // Update in database
  final updatedOrder = _order.copyWith(status: newStatus);
  await _dbService.updateOrder(updatedOrder);
  
  // 🎯 NEW: Send notification
  await _notificationService.notifyOrderStatusUpdate(
    updatedOrder, 
    oldStatus, 
    newStatus
  );
  
  // 🎯 NEW: If delivered, cancel reminders
  if (newStatus == 'delivered' || newStatus == 'completed') {
    await _notificationService.cancelOrderReminders(_order.uniqueId);
    await _notificationService.notifyOrderDelivered(updatedOrder);
  }
  
  setState(() {
    _order = updatedOrder;
  });
}
```

## Step 6: Add to Payment Recording

```dart
// lib/features/payments/screens/add_payment_screen.dart
Future<void> _savePayment() async {
  final payment = Payment(
    // ... payment details
    amount: _amount,
  );
  
  await _dbService.addPayment(payment);
  
  // Update order
  final updatedOrder = _order.copyWith(
    advancePaid: _order.advancePaid + _amount,
  );
  await _dbService.updateOrder(updatedOrder);
  
  // 🎯 NEW: Send payment notification
  await _notificationService.notifyPaymentReceived(updatedOrder, _amount);
  
  Navigator.pop(context);
}
```

## Step 7: Add to Home Screen AppBar

```dart
// lib/features/home/home_screen.dart
import 'package:tailer_app/features/notifications/widgets/notification_list_widget.dart';
import 'package:tailer_app/data/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  // ... existing code
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor App'),
        actions: [
          // 🎯 NEW: Notification bell with badge
          NotificationBadge(
            notificationService: _notificationService,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _showNotifications,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ... rest of your UI
    );
  }
  
  void _showNotifications() {
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
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
            const Expanded(
              child: NotificationListWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Step 8: Test Notifications

### Test 1: Create New Order
1. Create order with future delivery date
2. Check: Scheduled notifications should be created
3. Verify in device notification settings

### Test 2: Change Order Status
1. Change order status from "Pending" to "In Progress"
2. Check: Notification appears in status bar
3. Tap notification → Should navigate to order details

### Test 3: Record Payment
1. Add payment to order
2. Check: Payment notification appears
3. Verify in notification list

### Test 4: Notification Badge
1. Create few notifications
2. Check: Badge shows unread count
3. Mark as read → Badge updates

## Step 9: Run the App

```bash
flutter clean
flutter pub get
flutter run
```

## Common Issues & Fixes

### Issue 1: Notifications Not Showing

**Solution:**
```dart
// Check permissions
import 'package:tailer_app/data/services/notification_manager.dart';

final manager = NotificationManager();
final enabled = await manager.areNotificationsEnabled();

if (!enabled) {
  // Show dialog to enable notifications
  await manager.openNotificationSettings();
}
```

### Issue 2: Build Error - Unresolved Reference

**Solution:**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### Issue 3: Scheduled Notifications Not Appearing

**Solution:**
- Check delivery date is in the future
- Verify exact alarm permission granted
- Check device battery optimization settings

## Next Steps

1. ✅ Create test orders with future delivery dates
2. ✅ Test notification tap navigation
3. ✅ Test scheduled reminders (wait 1-2 days)
4. ✅ Create notification settings screen (optional)
5. ✅ Add custom notification sounds (optional)
6. ✅ Implement push notifications with Firebase (optional)

## Need Help?

Check the full documentation: `NOTIFICATION_IMPLEMENTATION_GUIDE.md`

---

**Ready to implement!** 🚀

Start with Step 1 and work through each step sequentially.
