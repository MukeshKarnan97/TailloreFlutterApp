import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tailor_model.dart';
import '../models/customer_model.dart';
import '../models/measurement_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../../core/utils/logger.dart';
import '../../core/config/app_config.dart';

/// LocalDatabaseService - A comprehensive local database service using SQLite
/// 
/// This service provides a singleton pattern for managing local database operations
/// with full CRUD functionality for all models in the tailor app.
/// 
/// Features:
/// - Singleton pattern for consistent database access
/// - Generic CRUD operations for reusability
/// - Proper error handling and logging
/// - Database versioning and migration support
/// - Connection pooling and performance optimization
class LocalDatabaseService {
  // Singleton instance
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  // Database instance
  static Database? _database;
  
  // Database configuration from AppConfig
  static String get _databaseName => AppConfig.databaseName;
  static int get _databaseVersion => AppConfig.databaseVersion;

  /// Get database instance (lazy initialization)
  /// Returns the database instance, creating it if it doesn't exist
  Future<Database> get database async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'get database', () async {
      _database ??= await _initDatabase();
      Logger.info('LocalDatabaseService', 'Database instance ready');
      return _database!;
    });
  }

  /// Initialize the database
  /// Creates the database file and sets up all tables
  Future<Database> _initDatabase() async {
    return Logger.traceAsyncMethod('LocalDatabaseService', '_initDatabase', () async {
      try {
        Logger.info('LocalDatabaseService', 'Initializing database...');
        // Get the database path
        final databasePath = await getDatabasesPath();
        final path = join(databasePath, _databaseName);
        Logger.debug('LocalDatabaseService', 'Database path: $path');

        // Open the database and create tables
        final db = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        );
        Logger.info('LocalDatabaseService', 'Database initialized successfully');
        return db;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to initialize database', error: e, stackTrace: stackTrace);
        throw Exception('Failed to initialize database: $e');
      }
    });
  }

  /// Configure database settings before opening
  /// Enables foreign key constraints for data integrity
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all database tables
  /// This method is called when the database is first created
  Future<void> _createTables(Database db, int version) async {
    Logger.startTrace('LocalDatabaseService', '_createTables', parameters: {'version': version});
    Logger.info('LocalDatabaseService', 'Creating database tables...');
    final batch = db.batch();

    // Create tailor table
    batch.execute('''
      CREATE TABLE tailor (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        auth_provider TEXT CHECK(auth_provider IN ('google', 'facebook', 'email')) NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create customer table
    batch.execute('''
      CREATE TABLE customer (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        tailor_id TEXT NOT NULL,
        name TEXT NOT NULL,
        gender TEXT,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT NOT NULL,
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE
      )
    ''');

    // Create measurement table
    batch.execute('''
      CREATE TABLE measurement (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        customer_id TEXT NOT NULL,
        type TEXT CHECK(type IN ('shirt', 'pant', 'blouse', 'suit', 'other')) NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE
      )
    ''');

    // Create order table
    batch.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        customer_id TEXT NOT NULL,
        tailor_id TEXT NOT NULL,
        service_type TEXT NOT NULL,
        status TEXT CHECK(status IN ('pending', 'cutting', 'stitching', 'ready', 'delivered')) NOT NULL,
        delivery_date TEXT NOT NULL,
        notes TEXT NOT NULL,
        design_image_url TEXT,
        total_amount REAL NOT NULL,
        advance_paid REAL NOT NULL,
        balance_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE,
        FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE
      )
    ''');

    // Create payment table
    batch.execute('''
      CREATE TABLE payment (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        order_id TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT CHECK(method IN ('cash', 'upi', 'card')) NOT NULL,
        paid_on TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
      )
    ''');

    // Create auth-related tables
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        profile_picture TEXT,
        is_email_verified INTEGER DEFAULT 0,
        is_phone_verified INTEGER DEFAULT 0,
        login_count INTEGER DEFAULT 0,
        last_login TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE auth_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        access_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        device_info TEXT,
        ip_address TEXT,
        user_agent TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        theme_mode TEXT DEFAULT 'system',
        language TEXT DEFAULT 'en',
        notifications_enabled INTEGER DEFAULT 1,
        biometric_enabled INTEGER DEFAULT 0,
        remember_me INTEGER DEFAULT 1,
        auto_logout_duration INTEGER DEFAULT 3600,
        custom_settings TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE login_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        login_time TEXT NOT NULL,
        device_info TEXT,
        ip_address TEXT,
        user_agent TEXT,
        login_method TEXT DEFAULT 'password',
        was_successful INTEGER NOT NULL,
        failure_reason TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    batch.execute('CREATE INDEX idx_customer_tailor_id ON customer (tailor_id)');
    batch.execute('CREATE INDEX idx_measurement_customer_id ON measurement (customer_id)');
    batch.execute('CREATE INDEX idx_order_customer_id ON orders (customer_id)');
    batch.execute('CREATE INDEX idx_order_tailor_id ON orders (tailor_id)');
    batch.execute('CREATE INDEX idx_payment_order_id ON payment (order_id)');
    batch.execute('CREATE INDEX idx_tailor_email ON tailor (email)');
    batch.execute('CREATE INDEX idx_order_status ON orders (status)');
    
    // Create auth-related indexes
    batch.execute('CREATE INDEX idx_users_email ON users (email)');
    batch.execute('CREATE INDEX idx_users_username ON users (username)');
    batch.execute('CREATE INDEX idx_auth_sessions_user_id ON auth_sessions (user_id)');
    batch.execute('CREATE INDEX idx_auth_sessions_session_id ON auth_sessions (session_id)');
    batch.execute('CREATE INDEX idx_auth_sessions_expires_at ON auth_sessions (expires_at)');
    batch.execute('CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id)');
    batch.execute('CREATE INDEX idx_login_history_user_id ON login_history (user_id)');
    batch.execute('CREATE INDEX idx_login_history_login_time ON login_history (login_time)');

    await batch.commit();
  }

  /// Handle database upgrades
  /// Called when database version is increased
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when needed
    // Example: if (oldVersion < 2) { /* migration code */ }
  }

  // ==================== GENERIC CRUD OPERATIONS ====================

  /// Generic insert operation
  /// Returns the inserted record's ID
  Future<int> insert(String table, Map<String, dynamic> data) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'insert', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Inserting into $table: ${data.keys.join(', ')}');
        final db = await database;
        final result = await db.insert(table, data);
        Logger.info('LocalDatabaseService', 'Successfully inserted into $table with ID: $result');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to insert into $table', error: e, stackTrace: stackTrace);
        throw Exception('Failed to insert into $table: $e');
      }
    }, parameters: {'table': table, 'dataKeys': data.keys.toList()});
  }

  /// Generic select operation with optional conditions
  /// Returns list of maps representing the records
  Future<List<Map<String, dynamic>>> select(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'select', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Selecting from $table with WHERE: $where');
        final db = await database;
        final result = await db.query(
          table,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
        Logger.info('LocalDatabaseService', 'Selected ${result.length} records from $table');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to select from $table', error: e, stackTrace: stackTrace);
        throw Exception('Failed to select from $table: $e');
      }
    }, parameters: {
      'table': table,
      'where': where,
      'limit': limit,
      'orderBy': orderBy
    });
  }

  /// Generic update operation
  /// Returns the number of affected rows
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Failed to update $table: $e');
    }
  }

  /// Generic delete operation
  /// Returns the number of deleted rows
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }

  /// Execute raw SQL query
  /// Use with caution - prefer typed methods when possible
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw query: $e');
    }
  }

  /// Execute raw SQL command (INSERT, UPDATE, DELETE)
  /// Returns the number of affected rows
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawUpdate(sql, arguments);
    } catch (e) {
      throw Exception('Failed to execute raw command: $e');
    }
  }

  // ==================== TAILOR OPERATIONS ====================

  /// Insert a new tailor
  Future<int> insertTailor(Tailor tailor) async {
    Logger.info('LocalDatabaseService', 'Inserting new tailor: ${tailor.name} (${tailor.email})');
    return await insert('tailor', {
      'id': tailor.id,
      'unique_id': tailor.uniqueId,
      'name': tailor.name,
      'shop_name': tailor.shopName,
      'email': tailor.email,
      'phone': tailor.phone,
      'password_hash': tailor.passwordHash,
      'auth_provider': tailor.authProvider,
      'address': tailor.address,
      'created_at': tailor.createdAt.toIso8601String(),
      'updated_at': tailor.updatedAt.toIso8601String(),
    });
  }

  /// Get tailor by email (for authentication)
  Future<Map<String, dynamic>?> getTailorByEmail(String email) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getTailorByEmail', () async {
      Logger.debug('LocalDatabaseService', 'Looking up tailor by email: $email');
      final results = await select(
        'tailor',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      final found = results.isNotEmpty;
      Logger.info('LocalDatabaseService', 'Tailor lookup by email: ${found ? 'FOUND' : 'NOT FOUND'}');
      return results.isNotEmpty ? results.first : null;
    }, parameters: {'email': email});
  }

  /// Get tailor by unique ID
  Future<Map<String, dynamic>?> getTailorByUniqueId(String uniqueId) async {
    final results = await select(
      'tailor',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update tailor information
  Future<int> updateTailor(String uniqueId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    return await update('tailor', data, where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  // ==================== CUSTOMER OPERATIONS ====================

  /// Insert a new customer
  Future<int> insertCustomer(Customer customer) async {
    return await insert('customer', {
      'id': customer.id,
      'unique_id': customer.uniqueId,
      'tailor_id': customer.tailorId,
      'name': customer.name,
      'gender': customer.gender,
      'phone': customer.phone,
      'email': customer.email,
      'address': customer.address,
      'notes': customer.notes,
      'is_deleted': customer.isDeleted ? 1 : 0,
      'created_at': customer.createdAt.toIso8601String(),
      'updated_at': customer.updatedAt.toIso8601String(),
    });
  }

  /// Insert a customer without foreign key constraint check
  /// Used for temporary insertion when tailor authentication is not yet implemented
  Future<int> insertCustomerWithoutForeignKeyCheck(Customer customer) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'insertCustomerWithoutForeignKeyCheck', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Inserting customer without foreign key check: ${customer.name}');
        final db = await database;
        
        // Temporarily disable foreign key constraints
        await db.execute('PRAGMA foreign_keys = OFF');
        
        final result = await db.insert('customer', {
          'id': customer.id,
          'unique_id': customer.uniqueId,
          'tailor_id': customer.tailorId,
          'name': customer.name,
          'gender': customer.gender,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'notes': customer.notes,
          'is_deleted': customer.isDeleted ? 1 : 0,
          'created_at': customer.createdAt.toIso8601String(),
          'updated_at': customer.updatedAt.toIso8601String(),
        });
        
        // Re-enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
        
        Logger.info('LocalDatabaseService', 'Successfully inserted customer without FK check with ID: $result');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to insert customer without FK check', error: e, stackTrace: stackTrace);
        // Re-enable foreign key constraints in case of error
        final db = await database;
        await db.execute('PRAGMA foreign_keys = ON');
        throw Exception('Failed to insert customer without FK check: $e');
      }
    }, parameters: {'customerName': customer.name});
  }

  /// Get all customers for a specific tailor
  Future<List<Map<String, dynamic>>> getCustomersByTailorId(String tailorId) async {
    return await select(
      'customer',
      where: 'tailor_id = ?',
      whereArgs: [tailorId],
      orderBy: 'name ASC',
    );
  }

  /// Get customer by unique ID
  Future<Map<String, dynamic>?> getCustomerByUniqueId(String uniqueId) async {
    final results = await select(
      'customer',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Search customers by name or phone
  Future<List<Map<String, dynamic>>> searchCustomers(String tailorId, String query) async {
    return await select(
      'customer',
      where: 'tailor_id = ? AND (name LIKE ? OR phone LIKE ?)',
      whereArgs: [tailorId, '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  /// Update customer information
  Future<int> updateCustomer(String uniqueId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    return await update('customer', data, where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  /// Delete customer (will cascade to related records)
  Future<int> deleteCustomer(String uniqueId) async {
    return await delete('customer', where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  // ==================== MEASUREMENT OPERATIONS ====================

  /// Insert a new measurement
  Future<int> insertMeasurement(Measurement measurement) async {
    return await insert('measurement', {
      'id': measurement.id,
      'unique_id': measurement.uniqueId,
      'customer_id': measurement.customerId,
      'type': measurement.type,
      'data': jsonEncode(measurement.data), // Convert Map to JSON string
      'created_at': measurement.createdAt.toIso8601String(),
      'updated_at': measurement.updatedAt.toIso8601String(),
    });
  }

  /// Get all measurements for a customer
  Future<List<Map<String, dynamic>>> getMeasurementsByCustomerId(String customerId) async {
    return await select(
      'measurement',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get measurements by type for a customer
  Future<List<Map<String, dynamic>>> getMeasurementsByType(String customerId, String type) async {
    return await select(
      'measurement',
      where: 'customer_id = ? AND type = ?',
      whereArgs: [customerId, type],
      orderBy: 'created_at DESC',
    );
  }

  /// Update measurement
  Future<int> updateMeasurement(String uniqueId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data.containsKey('data')) {
      data['data'] = jsonEncode(data['data']); // Ensure JSON string format
    }
    return await update('measurement', data, where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  /// Delete measurement
  Future<int> deleteMeasurement(String uniqueId) async {
    return await delete('measurement', where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  // ==================== ORDER OPERATIONS ====================

  /// Insert a new order
  Future<int> insertOrder(Order order) async {
    return await insert('orders', {
      'id': order.id,
      'unique_id': order.uniqueId,
      'customer_id': order.customerId,
      'tailor_id': order.tailorId,
      'service_type': order.serviceType,
      'status': order.status,
      'delivery_date': order.deliveryDate.toIso8601String(),
      'notes': order.notes,
      'design_image_url': order.designImageUrl,
      'total_amount': order.totalAmount,
      'advance_paid': order.advancePaid,
      'balance_amount': order.balanceAmount,
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': order.updatedAt.toIso8601String(),
    });
  }

  /// Get all orders for a tailor
  Future<List<Map<String, dynamic>>> getOrdersByTailorId(String tailorId) async {
    return await select(
      'orders',
      where: 'tailor_id = ?',
      whereArgs: [tailorId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get orders by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String tailorId, String status) async {
    return await select(
      'orders',
      where: 'tailor_id = ? AND status = ?',
      whereArgs: [tailorId, status],
      orderBy: 'delivery_date ASC',
    );
  }

  /// Get orders for a specific customer
  Future<List<Map<String, dynamic>>> getOrdersByCustomerId(String customerId) async {
    return await select(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get order by unique ID
  Future<Map<String, dynamic>?> getOrderByUniqueId(String uniqueId) async {
    final results = await select(
      'orders',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update order status
  Future<int> updateOrderStatus(String uniqueId, String status) async {
    return await update(
      'orders',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  /// Update order information
  Future<int> updateOrder(String uniqueId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data.containsKey('delivery_date') && data['delivery_date'] is DateTime) {
      data['delivery_date'] = (data['delivery_date'] as DateTime).toIso8601String();
    }
    return await update('orders', data, where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  /// Delete order
  Future<int> deleteOrder(String uniqueId) async {
    return await delete('orders', where: 'unique_id = ?', whereArgs: [uniqueId]);
  }

  // ==================== PAYMENT OPERATIONS ====================

  /// Insert a new payment
  Future<int> insertPayment(Payment payment) async {
    return await insert('payment', {
      'id': payment.id,
      'unique_id': payment.uniqueId,
      'order_id': payment.orderId,
      'amount': payment.amount,
      'method': payment.method,
      'paid_on': payment.paidOn.toIso8601String(),
    });
  }

  /// Get all payments for an order
  Future<List<Map<String, dynamic>>> getPaymentsByOrderId(String orderId) async {
    return await select(
      'payment',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'paid_on DESC',
    );
  }

  /// Get payments by method
  Future<List<Map<String, dynamic>>> getPaymentsByMethod(String method) async {
    return await select(
      'payment',
      where: 'method = ?',
      whereArgs: [method],
      orderBy: 'paid_on DESC',
    );
  }

  /// Get total payments for an order
  Future<double> getTotalPaymentsForOrder(String orderId) async {
    final result = await rawQuery(
      'SELECT SUM(amount) as total FROM payment WHERE order_id = ?',
      [orderId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    
    final tables = [
      'tailor', 
      'customer', 
      'measurement', 
      'orders', 
      'payment',
      'users',
      'auth_sessions',
      'user_preferences',
      'login_history'
    ];
    
    for (final table in tables) {
      final result = await rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = result.first['count'] as int;
    }
    
    return stats;
  }

  /// Clear all data (useful for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    
    // Delete in reverse order to respect foreign key constraints
    batch.delete('payment');
    batch.delete('orders');
    batch.delete('measurement');
    batch.delete('customer');
    batch.delete('tailor');
    
    // Clear auth-related tables
    batch.delete('login_history');
    batch.delete('auth_sessions');
    batch.delete('user_preferences');
    batch.delete('users');
    
    await batch.commit();
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete the entire database (use with extreme caution)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    await databaseFactory.deleteDatabase(path);
  }

  // ==================== COMPLEX QUERIES ====================

  /// Get customer with their order count
  Future<List<Map<String, dynamic>>> getCustomersWithOrderCount(String tailorId) async {
    return await rawQuery('''
      SELECT c.*, COUNT(o.id) as order_count 
      FROM customer c 
      LEFT JOIN orders o ON c.unique_id = o.customer_id 
      WHERE c.tailor_id = ? 
      GROUP BY c.id 
      ORDER BY order_count DESC, c.name ASC
    ''', [tailorId]);
  }

  /// Get tailor dashboard data
  Future<Map<String, dynamic>> getTailorDashboard(String tailorId) async {
    final results = await rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM customer WHERE tailor_id = ?) as total_customers,
        (SELECT COUNT(*) FROM orders WHERE tailor_id = ?) as total_orders,
        (SELECT COUNT(*) FROM orders WHERE tailor_id = ? AND status = 'pending') as pending_orders,
        (SELECT COUNT(*) FROM orders WHERE tailor_id = ? AND status = 'ready') as ready_orders,
        (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE tailor_id = ?) as total_revenue,
        (SELECT COALESCE(SUM(advance_paid), 0) FROM orders WHERE tailor_id = ?) as total_advance,
        (SELECT COALESCE(SUM(balance_amount), 0) FROM orders WHERE tailor_id = ?) as pending_balance
    ''', [tailorId, tailorId, tailorId, tailorId, tailorId, tailorId, tailorId]);
    
    return results.first;
  }

  /// Get orders with customer details
  Future<List<Map<String, dynamic>>> getOrdersWithCustomerDetails(String tailorId) async {
    return await rawQuery('''
      SELECT o.*, c.name as customer_name, c.phone as customer_phone
      FROM orders o
      JOIN customer c ON o.customer_id = c.unique_id
      WHERE o.tailor_id = ?
      ORDER BY o.created_at DESC
    ''', [tailorId]);
  }
}