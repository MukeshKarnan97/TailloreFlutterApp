import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  static int get _databaseVersion => 6; // Updated to include new tables

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
        dress_type TEXT NOT NULL,
        measurements TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
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
        payment_status TEXT CHECK(payment_status IN ('pending', 'partial', 'paid', 'overdue')) DEFAULT 'pending',
        delivery_date TEXT NOT NULL,
        notes TEXT NOT NULL,
        design_image_url TEXT,
        total_amount REAL NOT NULL,
        advance_paid REAL NOT NULL,
        balance_amount REAL NOT NULL,
        measurements TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
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
        method TEXT NOT NULL DEFAULT 'cash',
        notes TEXT DEFAULT '',
        transaction_id TEXT,
        paid_on TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
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
        measurement_unit TEXT DEFAULT 'inches',
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

    // Create notifications table
    batch.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT,
        order_id TEXT,
        customer_id TEXT,
        action_url TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (unique_id),
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id)
      )
    ''');

    // Create order cancellations table
    batch.execute('''
      CREATE TABLE order_cancellations (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        custom_reason TEXT,
        cancelled_by TEXT NOT NULL,
        cancelled_at TEXT NOT NULL,
        refund_amount REAL DEFAULT 0.0,
        refund_status TEXT DEFAULT 'not_applicable',
        refund_notes TEXT,
        additional_data TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (unique_id)
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

    // Create notification and cancellation indexes
    batch.execute('CREATE INDEX idx_notifications_created_at ON notifications (created_at)');
    batch.execute('CREATE INDEX idx_notifications_is_read ON notifications (is_read)');
    batch.execute('CREATE INDEX idx_notifications_order_id ON notifications (order_id)');
    batch.execute('CREATE INDEX idx_notifications_customer_id ON notifications (customer_id)');
    batch.execute('CREATE INDEX idx_order_cancellations_order_id ON order_cancellations (order_id)');
    batch.execute('CREATE INDEX idx_order_cancellations_cancelled_at ON order_cancellations (cancelled_at)');
    batch.execute('CREATE INDEX idx_order_cancellations_reason ON order_cancellations (reason)');

    await batch.commit();
  }

  /// Reset and recreate the entire database
  /// This will delete all existing data
  Future<void> resetDatabase() async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'resetDatabase', () async {
      try {
        Logger.warning('LocalDatabaseService', 'Resetting database - all data will be lost');
        
        // Close existing database connection
        if (_database != null) {
          await _database!.close();
          _database = null;
        }
        
        // Delete database file
        final databasePath = await getDatabasesPath();
        final path = join(databasePath, _databaseName);
        
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          Logger.info('LocalDatabaseService', 'Database file deleted: $path');
        }
        
        // Reinitialize database
        _database = await _initDatabase();
        Logger.info('LocalDatabaseService', 'Database reset completed successfully');
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to reset database', error: e, stackTrace: stackTrace);
        throw Exception('Failed to reset database: $e');
      }
    });
  }

  /// Handle database upgrades
  /// Called when database version is increased
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info('LocalDatabaseService', 'Upgrading database from version $oldVersion to $newVersion');
    
    // Add missing columns (version 4 to 5)
    if (oldVersion < 5) {
      try {
        // Check and add is_deleted column to orders table
        final orderColumns = await db.rawQuery("PRAGMA table_info(orders)");
        final hasIsDeletedInOrders = orderColumns.any((col) => col['name'] == 'is_deleted');
        final hasPaymentStatusInOrders = orderColumns.any((col) => col['name'] == 'payment_status');
        
        if (!hasIsDeletedInOrders) {
          Logger.info('LocalDatabaseService', 'Adding is_deleted column to orders table');
          await db.execute('ALTER TABLE orders ADD COLUMN is_deleted INTEGER DEFAULT 0');
        }
        
        if (!hasPaymentStatusInOrders) {
          Logger.info('LocalDatabaseService', 'Adding payment_status column to orders table');
          await db.execute('ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT "pending"');
        }
        
        // Check and add is_deleted column to payment table
        final paymentColumns = await db.rawQuery("PRAGMA table_info(payment)");
        final hasIsDeletedInPayment = paymentColumns.any((col) => col['name'] == 'is_deleted');
        
        if (!hasIsDeletedInPayment) {
          Logger.info('LocalDatabaseService', 'Adding is_deleted column to payment table');
          await db.execute('ALTER TABLE payment ADD COLUMN is_deleted INTEGER DEFAULT 0');
        }
        
        // Check and add is_deleted column to customer table
        final customerColumns = await db.rawQuery("PRAGMA table_info(customer)");
        final hasIsDeletedInCustomer = customerColumns.any((col) => col['name'] == 'is_deleted');
        
        if (!hasIsDeletedInCustomer) {
          Logger.info('LocalDatabaseService', 'Adding is_deleted column to customer table');
          await db.execute('ALTER TABLE customer ADD COLUMN is_deleted INTEGER DEFAULT 0');
        }
        
        Logger.info('LocalDatabaseService', 'Successfully added missing columns');
      } catch (e) {
        Logger.error('LocalDatabaseService', 'Failed to add missing columns', error: e);
      }
    }
    
    // Migrate measurement table schema (version 1/2 to 3)
    if (oldVersion < 3) {
      try {
        // Check current table schema
        final columns = await db.rawQuery("PRAGMA table_info(measurement)");
        Logger.debug('LocalDatabaseService', 'Current measurement table columns: ${columns.map((c) => c['name']).toList()}');
        
        bool hasOldSchema = columns.any((col) => col['name'] == 'type' || col['name'] == 'data');
        bool hasNewSchema = columns.any((col) => col['name'] == 'dress_type');
        
        if (hasOldSchema && !hasNewSchema) {
          Logger.info('LocalDatabaseService', 'Migrating measurement table from old schema to new schema');
          
          await db.transaction((txn) async {
            // Create new measurement table with correct schema
            await txn.execute('''
              CREATE TABLE measurement_new (
                id TEXT PRIMARY KEY,
                unique_id TEXT UNIQUE NOT NULL,
                customer_id TEXT NOT NULL,
                dress_type TEXT NOT NULL,
                measurements TEXT NOT NULL,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                is_deleted INTEGER DEFAULT 0,
                FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE
              )
            ''');
            
            // Migrate existing data if any
            final existingData = await txn.query('measurement');
            Logger.info('LocalDatabaseService', 'Migrating ${existingData.length} measurement records');
            
            for (final row in existingData) {
              await txn.insert('measurement_new', {
                'id': row['id'],
                'unique_id': row['unique_id'],
                'customer_id': row['customer_id'],
                'dress_type': row['type'] ?? 'other', // Map old 'type' to 'dress_type'
                'measurements': row['data'] ?? '{}', // Map old 'data' to 'measurements'
                'notes': '',
                'created_at': row['created_at'],
                'updated_at': row['updated_at'],
                'is_deleted': row['is_deleted'] ?? 0,
              });
            }
            
            // Drop old table and rename new one
            await txn.execute('DROP TABLE measurement');
            await txn.execute('ALTER TABLE measurement_new RENAME TO measurement');
          });
          
          Logger.info('LocalDatabaseService', 'Successfully migrated measurement table schema');
        } else if (!hasNewSchema) {
          Logger.warning('LocalDatabaseService', 'Measurement table has unexpected schema, recreating');
          await db.execute('DROP TABLE IF EXISTS measurement');
          await _createMeasurementTable(db);
        } else {
          Logger.info('LocalDatabaseService', 'Measurement table already has correct schema');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to migrate measurement table', error: e, stackTrace: stackTrace);
        
        // As a last resort, recreate the table (data will be lost)
        Logger.warning('LocalDatabaseService', 'Recreating measurement table due to migration failure');
        try {
          await db.execute('DROP TABLE IF EXISTS measurement');
          await _createMeasurementTable(db);
          Logger.info('LocalDatabaseService', 'Measurement table recreated successfully');
        } catch (recreateError) {
          Logger.error('LocalDatabaseService', 'Failed to recreate measurement table', error: recreateError);
          rethrow;
        }
      }
    }
    
    // Add measurement_unit column to user_preferences table (version 3 to 4)
    if (oldVersion < 4) {
      try {
        Logger.info('LocalDatabaseService', 'Adding measurement_unit column to user_preferences table');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(user_preferences)");
        final hasColumn = columns.any((col) => col['name'] == 'measurement_unit');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE user_preferences ADD COLUMN measurement_unit TEXT DEFAULT \'inches\'');
          Logger.info('LocalDatabaseService', 'Successfully added measurement_unit column');
        } else {
          Logger.info('LocalDatabaseService', 'measurement_unit column already exists');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add measurement_unit column', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }

      try {
        Logger.info('LocalDatabaseService', 'Adding measurements column to orders table');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(orders)");
        final hasColumn = columns.any((col) => col['name'] == 'measurements');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE orders ADD COLUMN measurements TEXT');
          Logger.info('LocalDatabaseService', 'Successfully added measurements column');
        } else {
          Logger.info('LocalDatabaseService', 'measurements column already exists');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add measurements column', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }
    
    // Fix payment table constraint (version 4 to 5)
    if (oldVersion < 5) {
      try {
        Logger.info('LocalDatabaseService', 'Fixing payment table constraints');
        
        // First, backup existing payment data
        final existingPayments = await db.query('payment');
        Logger.info('LocalDatabaseService', 'Backing up ${existingPayments.length} existing payments');
        
        // Drop the old payment table
        await db.execute('DROP TABLE IF EXISTS payment');
        
        // Create new payment table without the CHECK constraint
        await db.execute('''
          CREATE TABLE payment (
            id TEXT PRIMARY KEY,
            unique_id TEXT UNIQUE NOT NULL,
            order_id TEXT NOT NULL,
            amount REAL NOT NULL,
            method TEXT NOT NULL DEFAULT 'cash',
            notes TEXT DEFAULT '',
            transaction_id TEXT,
            paid_on TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE
          )
        ''');
        
        // Restore payment data
        for (final payment in existingPayments) {
          try {
            await db.insert('payment', payment);
          } catch (e) {
            Logger.warning('LocalDatabaseService', 'Failed to restore payment ${payment['unique_id']}: $e');
          }
        }
        
        Logger.info('LocalDatabaseService', 'Successfully fixed payment table constraints');
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to fix payment table', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }
  }

  /// Create measurement table with new schema
  Future<void> _createMeasurementTable(Database db) async {
    await db.execute('''
      CREATE TABLE measurement (
        id TEXT PRIMARY KEY,
        unique_id TEXT UNIQUE NOT NULL,
        customer_id TEXT NOT NULL,
        dress_type TEXT NOT NULL,
        measurements TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE
      )
    ''');
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
    return Logger.traceAsyncMethod('LocalDatabaseService', 'insertMeasurement', () async {
      try {
        // Validate measurement data
        if (measurement.customerId.isEmpty) {
          throw Exception('Customer ID cannot be empty');
        }
        if (measurement.dressType.isEmpty) {
          throw Exception('Dress type cannot be empty');
        }
        if (measurement.measurements.isEmpty) {
          throw Exception('At least one measurement is required');
        }
        
        Logger.debug('LocalDatabaseService', 'Inserting measurement: ${measurement.uniqueId} for customer: ${measurement.customerId}');
        
        final result = await insert('measurement', measurement.toMap());
        
        Logger.info('LocalDatabaseService', 'Successfully inserted measurement: ${measurement.uniqueId}');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to insert measurement', error: e, stackTrace: stackTrace);
        throw Exception('Failed to save measurement: $e');
      }
    }, parameters: {'measurementId': measurement.uniqueId, 'customerId': measurement.customerId});
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
  Future<List<Map<String, dynamic>>> getMeasurementsByType(String customerId, String dressType) async {
    return await select(
      'measurement',
      where: 'customer_id = ? AND dress_type = ?',
      whereArgs: [customerId, dressType],
      orderBy: 'created_at DESC',
    );
  }

  /// Update measurement
  Future<int> updateMeasurement(String uniqueId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data.containsKey('measurements')) {
      data['measurements'] = jsonEncode(data['measurements']); // Ensure JSON string format
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
      'measurements': order.measurements.isNotEmpty ? jsonEncode(order.measurements) : null,
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': order.updatedAt.toIso8601String(),
    });
  }

  /// Ensure measurements column exists in orders table
  Future<void> _ensureMeasurementsColumnExists(Database db) async {
    try {
      Logger.debug('LocalDatabaseService', 'Checking if measurements column exists in orders table');
      
      // Check if the column already exists
      final columns = await db.rawQuery("PRAGMA table_info(orders)");
      final hasColumn = columns.any((col) => col['name'] == 'measurements');
      
      if (!hasColumn) {
        Logger.info('LocalDatabaseService', 'Adding missing measurements column to orders table');
        await db.execute('ALTER TABLE orders ADD COLUMN measurements TEXT');
        Logger.info('LocalDatabaseService', 'Successfully added measurements column');
      } else {
        Logger.debug('LocalDatabaseService', 'measurements column already exists');
      }
    } catch (e, stackTrace) {
      Logger.error('LocalDatabaseService', 'Failed to ensure measurements column exists', error: e, stackTrace: stackTrace);
      // Don't rethrow as this might not be critical
    }
  }

  /// Insert an order without foreign key constraint check for tailor_id
  /// Used for temporary insertion when tailor authentication is not yet implemented
  Future<int> insertOrderWithoutTailorForeignKeyCheck(Order order) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'insertOrderWithoutTailorForeignKeyCheck', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Inserting order without tailor FK check: ${order.uniqueId}');
        final db = await database;
        
        // Ensure measurements column exists before insertion
        await _ensureMeasurementsColumnExists(db);
        
        // Temporarily disable foreign key constraints
        await db.execute('PRAGMA foreign_keys = OFF');
        
        final result = await db.insert('orders', {
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
          'measurements': order.measurements.isNotEmpty ? jsonEncode(order.measurements) : null,
          'created_at': order.createdAt.toIso8601String(),
          'updated_at': order.updatedAt.toIso8601String(),
        });
        
        // Re-enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
        
        Logger.info('LocalDatabaseService', 'Successfully inserted order without tailor FK check with ID: $result');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to insert order without tailor FK check', error: e, stackTrace: stackTrace);
        // Re-enable foreign key constraints in case of error
        final db = await database;
        await db.execute('PRAGMA foreign_keys = ON');
        throw Exception('Failed to insert order without tailor FK check: $e');
      }
    }, parameters: {'orderUniqueId': order.uniqueId});
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

  /// Get all orders as Order objects
  Future<List<Order>> getOrders() async {
    final maps = await select(
      'orders',
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => Order.fromMap(map)).toList();
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

  /// Soft delete order (mark as deleted without removing from database)
  Future<bool> softDeleteOrder(String uniqueId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'softDeleteOrder', () async {
      try {
        // Check if is_deleted column exists
        final columns = await (await database).rawQuery("PRAGMA table_info(orders)");
        final hasIsDeleted = columns.any((col) => col['name'] == 'is_deleted');
        
        if (!hasIsDeleted) {
          // Add the column if it doesn't exist
          await (await database).execute('ALTER TABLE orders ADD COLUMN is_deleted INTEGER DEFAULT 0');
          Logger.info('LocalDatabaseService', 'Added is_deleted column to orders table');
        }
        
        final result = await update(
          'orders',
          {
            'is_deleted': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
        );
        
        Logger.info('LocalDatabaseService', 'Soft deleted order: $uniqueId');
        return result > 0;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to soft delete order', 
                     error: e, stackTrace: stackTrace);
        return false;
      }
    });
  }

  /// Restore soft deleted order
  Future<bool> restoreOrder(String uniqueId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'restoreOrder', () async {
      try {
        final result = await update(
          'orders',
          {
            'is_deleted': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
        );
        
        Logger.info('LocalDatabaseService', 'Restored order: $uniqueId');
        return result > 0;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to restore order', 
                     error: e, stackTrace: stackTrace);
        return false;
      }
    });
  }

  /// Get deleted orders
  Future<List<Order>> getDeletedOrders() async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getDeletedOrders', () async {
      try {
        final results = await select('orders', where: 'is_deleted = 1');
        return results.map((map) => Order.fromMap(map)).toList();
      } catch (e) {
        // If is_deleted column doesn't exist, return empty list
        Logger.info('LocalDatabaseService', 'is_deleted column not found, returning empty deleted orders list');
        return <Order>[];
      }
    });
  }

  // ==================== PAYMENT OPERATIONS ====================

  /// Add a new payment
  Future<bool> addPayment(Payment payment) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'addPayment', () async {
      try {
        Logger.info('LocalDatabaseService', 'Adding payment: ${payment.uniqueId}');
        final result = await insert('payment', payment.toMap());
        Logger.info('LocalDatabaseService', 'Payment added successfully with ID: $result');
        return result > 0;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add payment', error: e, stackTrace: stackTrace);
        return false;
      }
    });
  }

  /// Get all payments for an order
  Future<List<Payment>> getPaymentsByOrderId(String orderId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPaymentsByOrderId', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting payments for order: $orderId');
        final result = await select(
          'payment',
          where: 'order_id = ? AND is_deleted = 0',
          whereArgs: [orderId],
          orderBy: 'paid_on DESC',
        );
        final payments = result.map((map) => Payment.fromMap(map)).toList();
        Logger.info('LocalDatabaseService', 'Found ${payments.length} payments for order $orderId');
        return payments;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get payments for order', error: e, stackTrace: stackTrace);
        return [];
      }
    });
  }

  /// Get payments by method
  Future<List<Payment>> getPaymentsByMethod(String method) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPaymentsByMethod', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting payments by method: $method');
        final result = await select(
          'payment',
          where: 'method = ? AND is_deleted = 0',
          whereArgs: [method],
          orderBy: 'paid_on DESC',
        );
        final payments = result.map((map) => Payment.fromMap(map)).toList();
        Logger.info('LocalDatabaseService', 'Found ${payments.length} payments with method $method');
        return payments;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get payments by method', error: e, stackTrace: stackTrace);
        return [];
      }
    });
  }

  /// Get all payments with optional filters
  Future<List<Payment>> getPayments({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPayments', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting all payments');
        final result = await select(
          'payment',
          where: 'is_deleted = 0',
          orderBy: orderBy ?? 'paid_on DESC',
          limit: limit,
          offset: offset,
        );
        final payments = result.map((map) => Payment.fromMap(map)).toList();
        Logger.info('LocalDatabaseService', 'Found ${payments.length} payments');
        return payments;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get payments', error: e, stackTrace: stackTrace);
        return [];
      }
    });
  }

  /// Get total payments for an order
  Future<double> getTotalPaymentsForOrder(String orderId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getTotalPaymentsForOrder', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting total payments for order: $orderId');
        final result = await rawQuery(
          'SELECT SUM(amount) as total FROM payment WHERE order_id = ? AND is_deleted = 0',
          [orderId],
        );
        final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
        Logger.info('LocalDatabaseService', 'Total payments for order $orderId: $total');
        return total;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get total payments for order', error: e, stackTrace: stackTrace);
        return 0.0;
      }
    });
  }

  /// Update payment
  Future<bool> updatePayment(Payment payment) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'updatePayment', () async {
      try {
        Logger.info('LocalDatabaseService', 'Updating payment: ${payment.uniqueId}');
        final result = await update(
          'payment',
          payment.toMap(),
          where: 'unique_id = ?',
          whereArgs: [payment.uniqueId],
        );
        Logger.info('LocalDatabaseService', 'Payment updated successfully: ${result > 0}');
        return result > 0;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to update payment', error: e, stackTrace: stackTrace);
        return false;
      }
    });
  }

  /// Delete payment (soft delete)
  Future<bool> deletePayment(String uniqueId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'deletePayment', () async {
      try {
        Logger.info('LocalDatabaseService', 'Deleting payment: $uniqueId');
        final result = await update(
          'payment',
          {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
        );
        Logger.info('LocalDatabaseService', 'Payment deleted successfully: ${result > 0}');
        return result > 0;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to delete payment', error: e, stackTrace: stackTrace);
        return false;
      }
    });
  }

  /// Get pending payment orders (orders with balance amount)
  Future<List<Order>> getPendingPaymentOrders() async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPendingPaymentOrders', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting orders with pending payments');
        final result = await rawQuery('''
          SELECT * FROM orders 
          WHERE (payment_status = 'pending' OR payment_status = 'partial') 
          AND is_deleted = 0
          ORDER BY delivery_date ASC
        ''');
        final orders = result.map((map) => Order.fromMap(map)).toList();
        Logger.info('LocalDatabaseService', 'Found ${orders.length} orders with pending payments');
        return orders;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get pending payment orders', error: e, stackTrace: stackTrace);
        return [];
      }
    });
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

  // ==================== USER PREFERENCES METHODS ====================

  /// Get user preferences by user ID
  Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    final results = await select('user_preferences', where: 'user_id = ?', whereArgs: [userId]);
    return results.isNotEmpty ? results.first : null;
  }

  /// Update user preferences
  Future<int> updateUserPreferences(int userId, Map<String, dynamic> preferences) async {
    preferences['updated_at'] = DateTime.now().toIso8601String();
    return await update('user_preferences', preferences, where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Insert user preferences
  Future<int> insertUserPreferences(Map<String, dynamic> preferences) async {
    preferences['created_at'] = DateTime.now().toIso8601String();
    preferences['updated_at'] = DateTime.now().toIso8601String();
    return await insert('user_preferences', preferences);
  }

  /// Get or create user preferences
  Future<Map<String, dynamic>> getOrCreateUserPreferences(int userId) async {
    final existing = await getUserPreferences(userId);
    if (existing != null) {
      return existing;
    }

    // Create default preferences
    final defaultPrefs = {
      'user_id': userId,
      'theme_mode': 'system',
      'language': 'en',
      'measurement_unit': 'inches',
      'notifications_enabled': 1,
      'biometric_enabled': 0,
      'remember_me': 1,
      'auto_logout_duration': 3600,
    };

    await insertUserPreferences(defaultPrefs);
    return await getUserPreferences(userId) ?? defaultPrefs;
  }

  /// Update user measurement unit preference
  Future<int> updateMeasurementUnit(int userId, String unit) async {
    return await updateUserPreferences(userId, {'measurement_unit': unit});
  }
}