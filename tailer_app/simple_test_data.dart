import 'package:flutter/material.dart';
import 'lib/data/services/local_db_service.dart';
import 'lib/data/models/customer_model.dart';
import 'lib/data/models/order_model.dart';

/// Simple test script to insert order data
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Inserting Test Order Data...');
  
  final dbService = LocalDatabaseService();
  
  // Wait for database to initialize
  await dbService.database;
  
  // Test customers
  final customers = [
    {'name': 'Raj Kumar', 'phone': '9876543210', 'address': '123 MG Road, Bangalore'},
    {'name': 'Priya Sharma', 'phone': '9876543211', 'address': '456 Brigade Road, Bangalore'},
    {'name': 'Arjun Singh', 'phone': '9876543212', 'address': '789 Commercial Street, Bangalore'},
  ];
  
  // Insert customers
  List<Customer> insertedCustomers = [];
  for (var customerData in customers) {
    final customer = Customer.create(
      tailorId: 'admin1@gmail.com',
      name: customerData['name']!,
      phone: customerData['phone']!,
      address: customerData['address']!,
      gender: 'Male',
    );
    
    try {
      await dbService.insertCustomerWithoutForeignKeyCheck(customer);
      insertedCustomers.add(customer);
      print('✅ Created customer: ${customer.name}');
    } catch (e) {
      print('❌ Failed to create customer: $e');
    }
  }
  
  // Order statuses to test
  final statuses = ['pending', 'cutting', 'stitching', 'in_progress', 'ready', 'completed', 'delivered'];
  final dressTypes = ['Shirt', 'Pant', 'Kurta'];
  
  // Insert 3 orders for each status
  int orderIndex = 0;
  for (String status in statuses) {
    print('\\nCreating $status orders...');
    
    for (int i = 0; i < 3; i++) {
      final customer = insertedCustomers[i % insertedCustomers.length];
      final dressType = dressTypes[i % dressTypes.length];
      
      double totalAmount = 2000.0 + (orderIndex * 100);
      double advance = status == 'completed' || status == 'delivered' ? totalAmount : totalAmount * 0.5;
      
      final order = Order.create(
        customerId: customer.uniqueId,
        tailorId: 'admin1@gmail.com',
        serviceType: dressType,
        status: status,
        deliveryDate: DateTime.now().add(Duration(days: 7)),
        notes: 'Test order - $status status',
        totalAmount: totalAmount,
        advancePaid: advance,
        balanceAmount: totalAmount - advance,
        measurements: {'chest': 40.0, 'waist': 36.0},
      );
      
      try {
        await dbService.insertOrderWithoutTailorForeignKeyCheck(order);
        print('  ✅ Order ${order.uniqueId}: $dressType - $status');
        orderIndex++;
      } catch (e) {
        print('  ❌ Failed to create order: $e');
      }
    }
  }
  
  print('\\n🎉 Test data insertion completed!');
  print('📊 Total orders created: ${statuses.length * 3}');
  print('🔐 Login with: admin1@gmail.com / Admin@123');
}
