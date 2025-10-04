import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';
import 'lib/data/models/customer_model.dart';
import 'lib/data/models/order_model.dart';

/// Test script to insert sample orders with all different statuses
/// Run this with: dart test_order_status_data.dart
class OrderStatusTestData {
  static const String TAILOR_ID = 'admin1@gmail.com';
  
  /// All possible order statuses in our system
  static const List<String> ORDER_STATUSES = [
    'pending',
    'cutting', 
    'stitching',
    'in_progress',
    'ready',
    'completed',
    'delivered'
  ];
  
  /// Sample dress types
  static const List<String> DRESS_TYPES = [
    'Shirt',
    'Pant', 
    'Suit',
    'Kurta',
    'Dress',
    'Blouse',
    'Lehenga'
  ];

  static Future<void> insertTestData() async {
    print('🚀 Starting Test Data Insertion...');
    print('📧 Using Tailor ID: $TAILOR_ID');
    
    try {
      final dbService = LocalDatabaseService();
      
      // Initialize database by accessing it
      await dbService.database;
      
      // First, create some test customers
      print('\n👥 Creating Test Customers...');
      List<Customer> customers = await _createTestCustomers(dbService);
      
      // Then create 3 orders for each status (21 total orders)
      print('\n📦 Creating Test Orders...');
      await _createTestOrders(dbService, customers);
      
      // Print summary
      await _printDataSummary(dbService);
      
      print('\n✅ Test data insertion completed successfully!');
      print('🔐 Login with: admin1@gmail.com / Admin@123');
      
    } catch (e, stackTrace) {
      print('❌ Error inserting test data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Create test customers
  static Future<List<Customer>> _createTestCustomers(LocalDatabaseService dbService) async {
    List<Customer> customers = [];
    
    final customerData = [
      {'name': 'Raj Kumar', 'phone': '9876543210', 'gender': 'Male', 'address': '123 MG Road, Bangalore'},
      {'name': 'Priya Sharma', 'phone': '9876543211', 'gender': 'Female', 'address': '456 Brigade Road, Bangalore'},
      {'name': 'Arjun Singh', 'phone': '9876543212', 'gender': 'Male', 'address': '789 Commercial Street, Bangalore'},
      {'name': 'Meera Patel', 'phone': '9876543213', 'gender': 'Female', 'address': '321 Koramangala, Bangalore'},
      {'name': 'Vikram Reddy', 'phone': '9876543214', 'gender': 'Male', 'address': '654 Indiranagar, Bangalore'},
      {'name': 'Anjali Gupta', 'phone': '9876543215', 'gender': 'Female', 'address': '987 Jayanagar, Bangalore'},
      {'name': 'Suresh Iyer', 'phone': '9876543216', 'gender': 'Male', 'address': '147 HSR Layout, Bangalore'},
      {'name': 'Kavya Nair', 'phone': '9876543217', 'gender': 'Female', 'address': '258 Whitefield, Bangalore'},
    ];
    
    for (int i = 0; i < customerData.length; i++) {
      final data = customerData[i];
      final customer = Customer.create(
        tailorId: TAILOR_ID,
        name: data['name']!,
        phone: data['phone']!,
        gender: data['gender'],
        address: data['address']!,
        email: '${data['name']!.toLowerCase().replaceAll(' ', '.')}@example.com',
        notes: 'Test customer ${i + 1} - Created for status testing',
      );
      
      try {
        await dbService.insertCustomerWithoutForeignKeyCheck(customer);
        customers.add(customer);
        print('  ✅ Created customer: ${customer.name} (${customer.uniqueId})');
      } catch (e) {
        print('  ❌ Failed to create customer ${customer.name}: $e');
      }
    }
    
    print('👥 Created ${customers.length} test customers');
    return customers;
  }

  /// Create test orders with different statuses
  static Future<void> _createTestOrders(LocalDatabaseService dbService, List<Customer> customers) async {
    int orderCount = 0;
    
    for (int statusIndex = 0; statusIndex < ORDER_STATUSES.length; statusIndex++) {
      final status = ORDER_STATUSES[statusIndex];
      print('\\n📋 Creating orders with status: $status');
      
      // Create 3 orders for each status
      for (int i = 0; i < 3; i++) {
        final customer = customers[orderCount % customers.length];
        final dressType = DRESS_TYPES[orderCount % DRESS_TYPES.length];
        
        // Calculate delivery date based on status
        DateTime deliveryDate = _getDeliveryDateForStatus(status);
        
        // Calculate amounts
        double totalAmount = 1500.0 + (orderCount * 200.0); // Varying amounts
        double advancePaid = _getAdvancePaidForStatus(status, totalAmount);
        double balanceAmount = totalAmount - advancePaid;
        
        // Sample measurements
        Map<String, double> measurements = _getSampleMeasurements(dressType);
        
        final order = Order.create(
          customerId: customer.uniqueId,
          tailorId: TAILOR_ID,
          serviceType: dressType,
          status: status,
          paymentStatus: _getPaymentStatusForStatus(status),
          deliveryDate: deliveryDate,
          notes: 'Test order ${orderCount + 1} - Status: $status - Customer: ${customer.name}',
          totalAmount: totalAmount,
          advancePaid: advancePaid,
          balanceAmount: balanceAmount,
          measurements: measurements,
        );
        
        try {
          await dbService.insertOrderWithoutTailorForeignKeyCheck(order);
          print('  ✅ Created order: ${order.uniqueId} - $dressType for ${customer.name} - $status');
          orderCount++;
        } catch (e) {
          print('  ❌ Failed to create order: $e');
        }
      }
    }
    
    print('\\n📦 Created $orderCount test orders total');
  }

  /// Get delivery date based on status
  static DateTime _getDeliveryDateForStatus(String status) {
    final now = DateTime.now();
    switch (status) {
      case 'pending':
        return now.add(Duration(days: 10)); // Future delivery
      case 'cutting':
        return now.add(Duration(days: 8));
      case 'stitching':
        return now.add(Duration(days: 6));
      case 'in_progress':
        return now.add(Duration(days: 4));
      case 'ready':
        return now.add(Duration(days: 2));
      case 'completed':
        return now.subtract(Duration(days: 1)); // Past delivery
      case 'delivered':
        return now.subtract(Duration(days: 3));
      default:
        return now.add(Duration(days: 7));
    }
  }

  /// Get advance paid amount based on status
  static double _getAdvancePaidForStatus(String status, double totalAmount) {
    switch (status) {
      case 'pending':
        return totalAmount * 0.3; // 30% advance
      case 'cutting':
      case 'stitching':
        return totalAmount * 0.5; // 50% advance
      case 'in_progress':
        return totalAmount * 0.7; // 70% advance
      case 'ready':
        return totalAmount * 0.8; // 80% advance
      case 'completed':
      case 'delivered':
        return totalAmount; // Fully paid
      default:
        return totalAmount * 0.3;
    }
  }

  /// Get payment status based on order status
  static String _getPaymentStatusForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'pending';
      case 'cutting':
      case 'stitching':
      case 'in_progress':
        return 'partial';
      case 'ready':
        return 'partial';
      case 'completed':
      case 'delivered':
        return 'paid';
      default:
        return 'pending';
    }
  }

  /// Get sample measurements for dress type
  static Map<String, double> _getSampleMeasurements(String dressType) {
    switch (dressType.toLowerCase()) {
      case 'shirt':
        return {
          'chest': 40.0,
          'waist': 36.0,
          'sleeve_length': 24.0,
          'shoulder': 16.0,
          'neck': 15.0,
        };
      case 'pant':
        return {
          'waist': 32.0,
          'length': 40.0,
          'hip': 38.0,
          'thigh': 22.0,
          'bottom': 14.0,
        };
      case 'suit':
        return {
          'chest': 42.0,
          'waist': 36.0,
          'sleeve_length': 25.0,
          'shoulder': 17.0,
          'pant_waist': 34.0,
          'pant_length': 42.0,
        };
      case 'kurta':
        return {
          'chest': 44.0,
          'length': 42.0,
          'sleeve_length': 22.0,
          'shoulder': 18.0,
          'neck': 16.0,
        };
      case 'dress':
        return {
          'bust': 36.0,
          'waist': 30.0,
          'hip': 38.0,
          'length': 40.0,
          'sleeve_length': 20.0,
        };
      case 'blouse':
        return {
          'bust': 34.0,
          'waist': 28.0,
          'sleeve_length': 12.0,
          'shoulder': 13.0,
          'neck': 13.0,
        };
      case 'lehenga':
        return {
          'bust': 36.0,
          'waist': 28.0,
          'hip': 40.0,
          'skirt_length': 42.0,
          'blouse_length': 14.0,
        };
      default:
        return {
          'chest': 38.0,
          'waist': 34.0,
          'length': 38.0,
        };
    }
  }

  /// Print data summary
  static Future<void> _printDataSummary(LocalDatabaseService dbService) async {
    print('\\n📊 DATABASE SUMMARY');
    print('=' * 50);
    
    try {
      // Get statistics
      final stats = await dbService.getDatabaseStats();
      print('📋 Table Statistics:');
      stats.forEach((table, count) {
        print('  • $table: $count records');
      });
      
      // Get orders by status
      print('\\n📦 Orders by Status:');
      for (final status in ORDER_STATUSES) {
        final orders = await dbService.getOrdersByStatus(TAILOR_ID, status);
        print('  • $status: ${orders.length} orders');
      }
      
      // Get customers
      final customers = await dbService.getCustomersWithOrderCount(TAILOR_ID);
      print('\\n👥 Customers with Order Count:');
      for (final customer in customers.take(5)) {
        print('  • ${customer['name']}: ${customer['order_count']} orders');
      }
      
    } catch (e) {
      print('❌ Error getting summary: $e');
    }
  }
}

/// Main function to run the test
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Order Status Test Data Generator');
  print('=' * 50);
  print('This will create sample orders with all status types');
  print('Login credentials: admin1@gmail.com / Admin@123');
  print('');
  
  await OrderStatusTestData.insertTestData();
  
  print('\\n🎉 Test completed! You can now test the app with sample data.');
  exit(0);
}