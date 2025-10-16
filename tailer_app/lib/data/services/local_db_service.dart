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
  static int get _databaseVersion => 13; // v13: Added is_active field to tailor table for local auth

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

    // Create tailor table (now used for authentication)
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
        profile_image_path TEXT,
        is_active INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
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
        FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
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
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
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
        measurement_id TEXT,
        image_path_1 TEXT,
        image_path_2 TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (measurement_id) REFERENCES measurement (unique_id) ON DELETE SET NULL ON UPDATE CASCADE
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
        FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
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
        FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
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
        FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    // Create indexes for better performance
    batch.execute('CREATE INDEX idx_customer_tailor_id ON customer (tailor_id)');
    batch.execute('CREATE INDEX idx_measurement_customer_id ON measurement (customer_id)');
    batch.execute('CREATE INDEX idx_order_customer_id ON orders (customer_id)');
    batch.execute('CREATE INDEX idx_order_tailor_id ON orders (tailor_id)');
    batch.execute('CREATE INDEX idx_order_measurement_id ON orders (measurement_id)');
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

    // Create composite indexes for common query patterns
    // For filtering orders by tailor and deletion status
    batch.execute('CREATE INDEX idx_orders_tailor_deleted ON orders (tailor_id, is_deleted)');
    // For filtering orders by status and deletion status
    batch.execute('CREATE INDEX idx_orders_status_deleted ON orders (status, is_deleted)');
    // For querying orders by tailor and status
    batch.execute('CREATE INDEX idx_orders_tailor_status ON orders (tailor_id, status)');
    // For payment queries by order and date
    batch.execute('CREATE INDEX idx_payment_order_date ON payment (order_id, paid_on)');
    // For payment queries by deletion status and date
    batch.execute('CREATE INDEX idx_payment_deleted_date ON payment (is_deleted, paid_on)');
    // For customer queries by tailor and deletion status
    batch.execute('CREATE INDEX idx_customer_tailor_deleted ON customer (tailor_id, is_deleted)');
    // For measurement queries by customer and deletion status
    batch.execute('CREATE INDEX idx_measurement_customer_deleted ON measurement (customer_id, is_deleted)');

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

    // Add measurement_id to orders table (version 6 to 7)
    if (oldVersion < 7) {
      try {
        Logger.info('LocalDatabaseService', 'Adding measurement_id column to orders table');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(orders)");
        final hasColumn = columns.any((col) => col['name'] == 'measurement_id');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE orders ADD COLUMN measurement_id TEXT');
          Logger.info('LocalDatabaseService', 'Successfully added measurement_id column');
          
          // Create index for better query performance
          await db.execute('CREATE INDEX IF NOT EXISTS idx_order_measurement_id ON orders (measurement_id)');
          Logger.info('LocalDatabaseService', 'Created index on measurement_id');
        } else {
          Logger.info('LocalDatabaseService', 'measurement_id column already exists');
        }

        // Add composite indexes for better query performance
        Logger.info('LocalDatabaseService', 'Creating composite indexes');
        
        // Check existing indexes to avoid duplicates
        final existingIndexes = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index'");
        final indexNames = existingIndexes.map((idx) => idx['name'] as String).toSet();
        
        final compositIndexes = {
          'idx_orders_tailor_deleted': 'CREATE INDEX IF NOT EXISTS idx_orders_tailor_deleted ON orders (tailor_id, is_deleted)',
          'idx_orders_status_deleted': 'CREATE INDEX IF NOT EXISTS idx_orders_status_deleted ON orders (status, is_deleted)',
          'idx_orders_tailor_status': 'CREATE INDEX IF NOT EXISTS idx_orders_tailor_status ON orders (tailor_id, status)',
          'idx_payment_order_date': 'CREATE INDEX IF NOT EXISTS idx_payment_order_date ON payment (order_id, paid_on)',
          'idx_payment_deleted_date': 'CREATE INDEX IF NOT EXISTS idx_payment_deleted_date ON payment (is_deleted, paid_on)',
          'idx_customer_tailor_deleted': 'CREATE INDEX IF NOT EXISTS idx_customer_tailor_deleted ON customer (tailor_id, is_deleted)',
          'idx_measurement_customer_deleted': 'CREATE INDEX IF NOT EXISTS idx_measurement_customer_deleted ON measurement (customer_id, is_deleted)',
        };
        
        for (final entry in compositIndexes.entries) {
          if (!indexNames.contains(entry.key)) {
            await db.execute(entry.value);
            Logger.info('LocalDatabaseService', 'Created composite index: ${entry.key}');
          }
        }
        
        Logger.info('LocalDatabaseService', 'Successfully completed version 7 migration');
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add measurement_id column', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }
    
    // Recreate all tables with proper FK references (version 7 to 8)
    if (oldVersion < 8) {
      try {
        Logger.info('LocalDatabaseService', '========================================');
        Logger.info('LocalDatabaseService', 'Starting Version 8 Migration');
        Logger.info('LocalDatabaseService', 'Recreating all tables with proper FK references');
        Logger.info('LocalDatabaseService', '========================================');
        
        await db.transaction((txn) async {
          // ============ BACKUP EXISTING DATA ============
          Logger.info('LocalDatabaseService', 'Step 1: Backing up existing data...');
          
          // Backup tailor data
          final tailorData = await txn.query('tailor');
          Logger.info('LocalDatabaseService', 'Backed up ${tailorData.length} tailors');
          
          // Backup customer data
          final customerData = await txn.query('customer');
          Logger.info('LocalDatabaseService', 'Backed up ${customerData.length} customers');
          
          // Backup measurement data
          final measurementData = await txn.query('measurement');
          Logger.info('LocalDatabaseService', 'Backed up ${measurementData.length} measurements');
          
          // Backup order data
          final orderData = await txn.query('orders');
          Logger.info('LocalDatabaseService', 'Backed up ${orderData.length} orders');
          
          // Backup payment data
          final paymentData = await txn.query('payment');
          Logger.info('LocalDatabaseService', 'Backed up ${paymentData.length} payments');
          
          // Backup users data
          final usersData = await txn.query('users');
          Logger.info('LocalDatabaseService', 'Backed up ${usersData.length} users');
          
          // Backup auth_sessions data
          final authSessionsData = await txn.query('auth_sessions');
          Logger.info('LocalDatabaseService', 'Backed up ${authSessionsData.length} auth sessions');
          
          // Backup user_preferences data
          final userPreferencesData = await txn.query('user_preferences');
          Logger.info('LocalDatabaseService', 'Backed up ${userPreferencesData.length} user preferences');
          
          // Backup login_history data
          final loginHistoryData = await txn.query('login_history');
          Logger.info('LocalDatabaseService', 'Backed up ${loginHistoryData.length} login history records');
          
          // Backup notifications data
          final notificationsData = await txn.query('notifications');
          Logger.info('LocalDatabaseService', 'Backed up ${notificationsData.length} notifications');
          
          // Backup order_cancellations data
          final orderCancellationsData = await txn.query('order_cancellations');
          Logger.info('LocalDatabaseService', 'Backed up ${orderCancellationsData.length} order cancellations');
          
          // ============ DROP OLD TABLES ============
          Logger.info('LocalDatabaseService', 'Step 2: Dropping old tables...');
          
          await txn.execute('DROP TABLE IF EXISTS order_cancellations');
          await txn.execute('DROP TABLE IF EXISTS notifications');
          await txn.execute('DROP TABLE IF EXISTS login_history');
          await txn.execute('DROP TABLE IF EXISTS user_preferences');
          await txn.execute('DROP TABLE IF EXISTS auth_sessions');
          await txn.execute('DROP TABLE IF EXISTS users');
          await txn.execute('DROP TABLE IF EXISTS payment');
          await txn.execute('DROP TABLE IF EXISTS orders');
          await txn.execute('DROP TABLE IF EXISTS measurement');
          await txn.execute('DROP TABLE IF EXISTS customer');
          await txn.execute('DROP TABLE IF EXISTS tailor');
          
          Logger.info('LocalDatabaseService', 'All old tables dropped');
          
          // ============ CREATE NEW TABLES WITH PROPER FK ============
          Logger.info('LocalDatabaseService', 'Step 3: Creating new tables with proper FK references...');
          
          // Create tailor table
          await txn.execute('''
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
          Logger.info('LocalDatabaseService', '✓ Created tailor table');
          
          // Create customer table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created customer table with FK CASCADE');
          
          // Create measurement table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created measurement table with FK CASCADE');
          
          // Create orders table with CASCADE and measurement_id
          await txn.execute('''
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
              measurement_id TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_deleted INTEGER DEFAULT 0,
              FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
              FOREIGN KEY (tailor_id) REFERENCES tailor (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
              FOREIGN KEY (measurement_id) REFERENCES measurement (unique_id) ON DELETE SET NULL ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created orders table with FK CASCADE and measurement_id');
          
          // Create payment table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created payment table with FK CASCADE');
          
          // Create users table
          await txn.execute('''
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
          Logger.info('LocalDatabaseService', '✓ Created users table');
          
          // Create auth_sessions table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created auth_sessions table with FK CASCADE');
          
          // Create user_preferences table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created user_preferences table with FK CASCADE');
          
          // Create login_history table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created login_history table with FK CASCADE');
          
          // Create notifications table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE,
              FOREIGN KEY (customer_id) REFERENCES customer (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created notifications table with FK CASCADE');
          
          // Create order_cancellations table with CASCADE
          await txn.execute('''
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
              FOREIGN KEY (order_id) REFERENCES orders (unique_id) ON DELETE CASCADE ON UPDATE CASCADE
            )
          ''');
          Logger.info('LocalDatabaseService', '✓ Created order_cancellations table with FK CASCADE');
          
          // ============ CREATE ALL INDEXES ============
          Logger.info('LocalDatabaseService', 'Step 4: Creating indexes...');
          
          // Basic indexes
          await txn.execute('CREATE INDEX idx_customer_tailor_id ON customer (tailor_id)');
          await txn.execute('CREATE INDEX idx_measurement_customer_id ON measurement (customer_id)');
          await txn.execute('CREATE INDEX idx_order_customer_id ON orders (customer_id)');
          await txn.execute('CREATE INDEX idx_order_tailor_id ON orders (tailor_id)');
          await txn.execute('CREATE INDEX idx_order_measurement_id ON orders (measurement_id)');
          await txn.execute('CREATE INDEX idx_payment_order_id ON payment (order_id)');
          await txn.execute('CREATE INDEX idx_tailor_email ON tailor (email)');
          await txn.execute('CREATE INDEX idx_order_status ON orders (status)');
          
          // Auth-related indexes
          await txn.execute('CREATE INDEX idx_users_email ON users (email)');
          await txn.execute('CREATE INDEX idx_users_username ON users (username)');
          await txn.execute('CREATE INDEX idx_auth_sessions_user_id ON auth_sessions (user_id)');
          await txn.execute('CREATE INDEX idx_auth_sessions_session_id ON auth_sessions (session_id)');
          await txn.execute('CREATE INDEX idx_auth_sessions_expires_at ON auth_sessions (expires_at)');
          await txn.execute('CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id)');
          await txn.execute('CREATE INDEX idx_login_history_user_id ON login_history (user_id)');
          await txn.execute('CREATE INDEX idx_login_history_login_time ON login_history (login_time)');
          
          // Notification and cancellation indexes
          await txn.execute('CREATE INDEX idx_notifications_created_at ON notifications (created_at)');
          await txn.execute('CREATE INDEX idx_notifications_is_read ON notifications (is_read)');
          await txn.execute('CREATE INDEX idx_notifications_order_id ON notifications (order_id)');
          await txn.execute('CREATE INDEX idx_notifications_customer_id ON notifications (customer_id)');
          await txn.execute('CREATE INDEX idx_order_cancellations_order_id ON order_cancellations (order_id)');
          await txn.execute('CREATE INDEX idx_order_cancellations_cancelled_at ON order_cancellations (cancelled_at)');
          await txn.execute('CREATE INDEX idx_order_cancellations_reason ON order_cancellations (reason)');
          
          // Composite indexes for common query patterns
          await txn.execute('CREATE INDEX idx_orders_tailor_deleted ON orders (tailor_id, is_deleted)');
          await txn.execute('CREATE INDEX idx_orders_status_deleted ON orders (status, is_deleted)');
          await txn.execute('CREATE INDEX idx_orders_tailor_status ON orders (tailor_id, status)');
          await txn.execute('CREATE INDEX idx_payment_order_date ON payment (order_id, paid_on)');
          await txn.execute('CREATE INDEX idx_payment_deleted_date ON payment (is_deleted, paid_on)');
          await txn.execute('CREATE INDEX idx_customer_tailor_deleted ON customer (tailor_id, is_deleted)');
          await txn.execute('CREATE INDEX idx_measurement_customer_deleted ON measurement (customer_id, is_deleted)');
          
          Logger.info('LocalDatabaseService', '✓ Created all indexes');
          
          // ============ RESTORE DATA ============
          Logger.info('LocalDatabaseService', 'Step 5: Restoring data...');
          
          // Restore tailor data
          for (final row in tailorData) {
            await txn.insert('tailor', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${tailorData.length} tailors');
          
          // Restore customer data
          for (final row in customerData) {
            await txn.insert('customer', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${customerData.length} customers');
          
          // Restore measurement data
          for (final row in measurementData) {
            await txn.insert('measurement', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${measurementData.length} measurements');
          
          // Restore order data (add measurement_id if missing)
          for (final row in orderData) {
            // Ensure measurement_id exists in the row
            if (!row.containsKey('measurement_id')) {
              row['measurement_id'] = null;
            }
            await txn.insert('orders', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${orderData.length} orders');
          
          // Restore payment data
          for (final row in paymentData) {
            await txn.insert('payment', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${paymentData.length} payments');
          
          // Restore users data
          for (final row in usersData) {
            await txn.insert('users', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${usersData.length} users');
          
          // Restore auth_sessions data
          for (final row in authSessionsData) {
            await txn.insert('auth_sessions', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${authSessionsData.length} auth sessions');
          
          // Restore user_preferences data
          for (final row in userPreferencesData) {
            await txn.insert('user_preferences', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${userPreferencesData.length} user preferences');
          
          // Restore login_history data
          for (final row in loginHistoryData) {
            await txn.insert('login_history', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${loginHistoryData.length} login history records');
          
          // Restore notifications data
          for (final row in notificationsData) {
            await txn.insert('notifications', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${notificationsData.length} notifications');
          
          // Restore order_cancellations data
          for (final row in orderCancellationsData) {
            await txn.insert('order_cancellations', row);
          }
          Logger.info('LocalDatabaseService', '✓ Restored ${orderCancellationsData.length} order cancellations');
          
          Logger.info('LocalDatabaseService', '========================================');
          Logger.info('LocalDatabaseService', 'Version 8 Migration Completed Successfully!');
          Logger.info('LocalDatabaseService', 'All tables recreated with proper FK CASCADE');
          Logger.info('LocalDatabaseService', 'All data restored successfully');
          Logger.info('LocalDatabaseService', '========================================');
        });
        
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'CRITICAL: Version 8 migration failed!', error: e, stackTrace: stackTrace);
        Logger.error('LocalDatabaseService', 'Database may be in an inconsistent state');
        throw Exception('Failed to migrate to version 8: $e');
      }
    }
    
    // Add is_deleted column to tailor table (version 9 to 10)
    if (oldVersion < 10) {
      try {
        Logger.info('LocalDatabaseService', 'Adding is_deleted column to tailor table');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(tailor)");
        final hasColumn = columns.any((col) => col['name'] == 'is_deleted');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE tailor ADD COLUMN is_deleted INTEGER DEFAULT 0');
          Logger.info('LocalDatabaseService', 'Successfully added is_deleted column to tailor table');
        } else {
          Logger.info('LocalDatabaseService', 'is_deleted column already exists in tailor table');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add is_deleted column to tailor table', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }

    // Add profile_image_path column to tailor table (version 10 to 11)
    if (oldVersion < 11) {
      try {
        Logger.info('LocalDatabaseService', 'Adding profile_image_path column to tailor table');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(tailor)");
        final hasColumn = columns.any((col) => col['name'] == 'profile_image_path');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE tailor ADD COLUMN profile_image_path TEXT');
          Logger.info('LocalDatabaseService', 'Successfully added profile_image_path column to tailor table');
        } else {
          Logger.info('LocalDatabaseService', 'profile_image_path column already exists in tailor table');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add profile_image_path column to tailor table', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }

    // Add image_path_1 and image_path_2 columns to orders table (version 11 to 12)
    if (oldVersion < 12) {
      try {
        Logger.info('LocalDatabaseService', 'Adding image columns to orders table');
        
        // Check if the columns already exist
        final columns = await db.rawQuery("PRAGMA table_info(orders)");
        final hasImagePath1 = columns.any((col) => col['name'] == 'image_path_1');
        final hasImagePath2 = columns.any((col) => col['name'] == 'image_path_2');
        
        if (!hasImagePath1) {
          await db.execute('ALTER TABLE orders ADD COLUMN image_path_1 TEXT');
          Logger.info('LocalDatabaseService', 'Successfully added image_path_1 column to orders table');
        } else {
          Logger.info('LocalDatabaseService', 'image_path_1 column already exists in orders table');
        }
        
        if (!hasImagePath2) {
          await db.execute('ALTER TABLE orders ADD COLUMN image_path_2 TEXT');
          Logger.info('LocalDatabaseService', 'Successfully added image_path_2 column to orders table');
        } else {
          Logger.info('LocalDatabaseService', 'image_path_2 column already exists in orders table');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add image columns to orders table', error: e, stackTrace: stackTrace);
        // Don't rethrow as this is not critical for app functionality
      }
    }

    // Add is_active column to tailor table for local authentication (version 12 to 13)
    if (oldVersion < 13) {
      try {
        Logger.info('LocalDatabaseService', 'Adding is_active column to tailor table for local auth');
        
        // Check if the column already exists
        final columns = await db.rawQuery("PRAGMA table_info(tailor)");
        final hasColumn = columns.any((col) => col['name'] == 'is_active');
        
        if (!hasColumn) {
          await db.execute('ALTER TABLE tailor ADD COLUMN is_active INTEGER DEFAULT 0');
          Logger.info('LocalDatabaseService', 'Successfully added is_active column to tailor table');
          
          // Create index for better query performance
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tailor_active ON tailor (is_active)');
          Logger.info('LocalDatabaseService', 'Created index on is_active');
        } else {
          Logger.info('LocalDatabaseService', 'is_active column already exists in tailor table');
        }
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to add is_active column to tailor table', error: e, stackTrace: stackTrace);
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
      'measurement_id': order.measurementId, // NEW: Add measurement reference
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
        Logger.debug('LocalDatabaseService', 'Order image paths - Path1: ${order.imagePath1}, Path2: ${order.imagePath2}');
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
          'measurement_id': order.measurementId, // NEW: Add measurement reference
          'image_path_1': order.imagePath1, // CRITICAL: Add garment image 1
          'image_path_2': order.imagePath2, // CRITICAL: Add garment image 2
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
  Future<List<Order>> getOrders({String? tailorId}) async {
    final maps = await select(
      'orders',
      where: tailorId != null ? 'tailor_id = ?' : null,
      whereArgs: tailorId != null ? [tailorId] : null,
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
  Future<List<Order>> getDeletedOrders({String? tailorId}) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getDeletedOrders', () async {
      try {
        String where = 'is_deleted = 1';
        List<Object?> whereArgs = [];
        
        if (tailorId != null) {
          where += ' AND tailor_id = ?';
          whereArgs.add(tailorId);
        }
        
        final results = await select('orders', where: where, whereArgs: whereArgs);
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
    String? tailorId, // Filter by tailor
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPayments', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting all payments${tailorId != null ? ' for tailor: $tailorId' : ''}');
        
        if (tailorId != null) {
          // Join with orders table to filter by tailor_id
          final result = await rawQuery(
            '''
            SELECT p.* FROM payment p
            INNER JOIN orders o ON p.order_id = o.unique_id
            WHERE p.is_deleted = 0 AND o.tailor_id = ?
            ORDER BY ${orderBy ?? 'p.paid_on DESC'}
            ${limit != null ? 'LIMIT $limit' : ''}
            ${offset != null ? 'OFFSET $offset' : ''}
            ''',
            [tailorId],
          );
          final payments = result.map((map) => Payment.fromMap(map)).toList();
          Logger.info('LocalDatabaseService', 'Found ${payments.length} payments for tailor $tailorId');
          return payments;
        } else {
          // Get all payments (no filtering)
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
        }
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

  // ==================== OPTIMIZED QUERY METHODS ====================

  /// Get orders with full details (customer, payments, measurements) using JOINs
  /// Eliminates N+1 query problem by fetching all related data in one query
  Future<List<Map<String, dynamic>>> getOrdersWithFullDetails({
    String? tailorId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getOrdersWithFullDetails', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting orders with full details');
        
        String sql = '''
          SELECT 
            o.*,
            c.name as customer_name,
            c.phone as customer_phone,
            c.email as customer_email,
            c.address as customer_address,
            m.dress_type as measurement_dress_type,
            m.measurements as measurement_data,
            m.notes as measurement_notes,
            (SELECT COALESCE(SUM(p.amount), 0) 
             FROM payment p 
             WHERE p.order_id = o.unique_id AND p.is_deleted = 0) as total_paid,
            (SELECT COUNT(*) 
             FROM payment p 
             WHERE p.order_id = o.unique_id AND p.is_deleted = 0) as payment_count
          FROM orders o
          INNER JOIN customer c ON o.customer_id = c.unique_id
          LEFT JOIN measurement m ON o.measurement_id = m.unique_id
          WHERE o.is_deleted = 0
        ''';
        
        List<dynamic> args = [];
        
        if (tailorId != null) {
          sql += ' AND o.tailor_id = ?';
          args.add(tailorId);
        }
        
        if (status != null) {
          sql += ' AND o.status = ?';
          args.add(status);
        }
        
        sql += ' ORDER BY o.created_at DESC';
        
        if (limit != null) {
          sql += ' LIMIT ?';
          args.add(limit);
          
          if (offset != null) {
            sql += ' OFFSET ?';
            args.add(offset);
          }
        }
        
        final result = await rawQuery(sql, args);
        Logger.info('LocalDatabaseService', 'Found ${result.length} orders with full details');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get orders with full details', 
                     error: e, stackTrace: stackTrace);
        return [];
      }
    }, parameters: {'tailorId': tailorId, 'status': status});
  }

  /// Get customer with comprehensive statistics
  /// Includes order count, total revenue, pending balance, and payment stats
  Future<Map<String, dynamic>?> getCustomerWithStats(String customerId) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getCustomerWithStats', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting customer stats for: $customerId');
        
        final result = await rawQuery('''
          SELECT 
            c.*,
            COUNT(DISTINCT o.id) as total_orders,
            COUNT(DISTINCT CASE WHEN o.status = 'pending' THEN o.id END) as pending_orders,
            COUNT(DISTINCT CASE WHEN o.status = 'in_progress' THEN o.id END) as in_progress_orders,
            COUNT(DISTINCT CASE WHEN o.status = 'ready' THEN o.id END) as ready_orders,
            COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.id END) as delivered_orders,
            COALESCE(SUM(o.total_amount), 0) as total_revenue,
            COALESCE(SUM(o.advance_paid), 0) as total_advance,
            COALESCE(SUM(o.balance_amount), 0) as pending_balance,
            COUNT(DISTINCT m.id) as total_measurements,
            (SELECT COUNT(*) FROM payment p 
             INNER JOIN orders ord ON p.order_id = ord.unique_id 
             WHERE ord.customer_id = c.unique_id AND p.is_deleted = 0) as total_payments
          FROM customer c
          LEFT JOIN orders o ON c.unique_id = o.customer_id AND o.is_deleted = 0
          LEFT JOIN measurement m ON c.unique_id = m.customer_id AND m.is_deleted = 0
          WHERE c.unique_id = ?
          GROUP BY c.id
        ''', [customerId]);
        
        if (result.isEmpty) {
          Logger.warning('LocalDatabaseService', 'Customer not found: $customerId');
          return null;
        }
        
        Logger.info('LocalDatabaseService', 'Retrieved customer stats successfully');
        return result.first;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get customer stats', 
                     error: e, stackTrace: stackTrace);
        return null;
      }
    }, parameters: {'customerId': customerId});
  }

  /// Get payment analytics data for reports
  /// Includes payments grouped by date, method, and status
  Future<Map<String, dynamic>> getPaymentAnalyticsData({
    String? tailorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPaymentAnalyticsData', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting payment analytics');
        
        String whereClause = 'p.is_deleted = 0';
        List<dynamic> args = [];
        
        if (tailorId != null) {
          whereClause += ' AND o.tailor_id = ?';
          args.add(tailorId);
        }
        
        if (startDate != null) {
          whereClause += ' AND p.paid_on >= ?';
          args.add(startDate.toIso8601String());
        }
        
        if (endDate != null) {
          whereClause += ' AND p.paid_on <= ?';
          args.add(endDate.toIso8601String());
        }
        
        // Get total payments and amount
        final totalResult = await rawQuery('''
          SELECT 
            COUNT(*) as total_count,
            COALESCE(SUM(p.amount), 0) as total_amount
          FROM payment p
          INNER JOIN orders o ON p.order_id = o.unique_id
          WHERE $whereClause
        ''', args);
        
        // Get payments by method
        final methodResult = await rawQuery('''
          SELECT 
            p.method,
            COUNT(*) as count,
            COALESCE(SUM(p.amount), 0) as amount
          FROM payment p
          INNER JOIN orders o ON p.order_id = o.unique_id
          WHERE $whereClause
          GROUP BY p.method
          ORDER BY amount DESC
        ''', args);
        
        // Get recent payments with customer details
        final recentResult = await rawQuery('''
          SELECT 
            p.*,
            c.name as customer_name,
            c.phone as customer_phone,
            o.unique_id as order_unique_id,
            o.service_type as order_service_type
          FROM payment p
          INNER JOIN orders o ON p.order_id = o.unique_id
          INNER JOIN customer c ON o.customer_id = c.unique_id
          WHERE $whereClause
          ORDER BY p.paid_on DESC
          LIMIT 50
        ''', args);
        
        Logger.info('LocalDatabaseService', 'Retrieved payment analytics successfully');
        
        return {
          'total_count': totalResult.first['total_count'],
          'total_amount': totalResult.first['total_amount'],
          'by_method': methodResult,
          'recent_payments': recentResult,
        };
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get payment analytics', 
                     error: e, stackTrace: stackTrace);
        return {
          'total_count': 0,
          'total_amount': 0.0,
          'by_method': [],
          'recent_payments': [],
        };
      }
    }, parameters: {'tailorId': tailorId, 'startDate': startDate, 'endDate': endDate});
  }

  /// Get orders with pending payments and customer details
  /// Optimized for payment collection screen
  Future<List<Map<String, dynamic>>> getOrdersWithPendingPayments({
    String? tailorId,
    int? limit,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getOrdersWithPendingPayments', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting orders with pending payments');
        
        String sql = '''
          SELECT 
            o.*,
            c.name as customer_name,
            c.phone as customer_phone,
            c.email as customer_email,
            (SELECT COALESCE(SUM(p.amount), 0) 
             FROM payment p 
             WHERE p.order_id = o.unique_id AND p.is_deleted = 0) as total_paid,
            (o.total_amount - COALESCE((SELECT SUM(p.amount) 
             FROM payment p 
             WHERE p.order_id = o.unique_id AND p.is_deleted = 0), 0)) as remaining_balance
          FROM orders o
          INNER JOIN customer c ON o.customer_id = c.unique_id
          WHERE o.is_deleted = 0
          AND (o.payment_status = 'pending' OR o.payment_status = 'partial')
        ''';
        
        List<dynamic> args = [];
        
        if (tailorId != null) {
          sql += ' AND o.tailor_id = ?';
          args.add(tailorId);
        }
        
        sql += ' ORDER BY o.delivery_date ASC';
        
        if (limit != null) {
          sql += ' LIMIT ?';
          args.add(limit);
        }
        
        final result = await rawQuery(sql, args);
        Logger.info('LocalDatabaseService', 'Found ${result.length} orders with pending payments');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get orders with pending payments', 
                     error: e, stackTrace: stackTrace);
        return [];
      }
    }, parameters: {'tailorId': tailorId, 'limit': limit});
  }

  /// Get payment history with full details (order, customer info)
  /// Optimized for payment history screen
  Future<List<Map<String, dynamic>>> getPaymentHistoryWithDetails({
    String? tailorId,
    String? customerId,
    String? method,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return Logger.traceAsyncMethod('LocalDatabaseService', 'getPaymentHistoryWithDetails', () async {
      try {
        Logger.debug('LocalDatabaseService', 'Getting payment history with details');
        
        String sql = '''
          SELECT 
            p.*,
            c.name as customer_name,
            c.phone as customer_phone,
            o.unique_id as order_unique_id,
            o.service_type,
            o.total_amount as order_total,
            o.status as order_status
          FROM payment p
          INNER JOIN orders o ON p.order_id = o.unique_id
          INNER JOIN customer c ON o.customer_id = c.unique_id
          WHERE p.is_deleted = 0
        ''';
        
        List<dynamic> args = [];
        
        if (tailorId != null) {
          sql += ' AND o.tailor_id = ?';
          args.add(tailorId);
        }
        
        if (customerId != null) {
          sql += ' AND o.customer_id = ?';
          args.add(customerId);
        }
        
        if (method != null) {
          sql += ' AND p.method = ?';
          args.add(method);
        }
        
        if (startDate != null) {
          sql += ' AND p.paid_on >= ?';
          args.add(startDate.toIso8601String());
        }
        
        if (endDate != null) {
          sql += ' AND p.paid_on <= ?';
          args.add(endDate.toIso8601String());
        }
        
        sql += ' ORDER BY p.paid_on DESC';
        
        if (limit != null) {
          sql += ' LIMIT ?';
          args.add(limit);
          
          if (offset != null) {
            sql += ' OFFSET ?';
            args.add(offset);
          }
        }
        
        final result = await rawQuery(sql, args);
        Logger.info('LocalDatabaseService', 'Found ${result.length} payment records');
        return result;
      } catch (e, stackTrace) {
        Logger.error('LocalDatabaseService', 'Failed to get payment history', 
                     error: e, stackTrace: stackTrace);
        return [];
      }
    }, parameters: {
      'tailorId': tailorId,
      'customerId': customerId,
      'method': method,
      'startDate': startDate,
      'endDate': endDate,
    });
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