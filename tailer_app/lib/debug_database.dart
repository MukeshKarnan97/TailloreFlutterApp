import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';

/// Debug script to inspect database path and tailor table
/// 
/// Run this with: dart run lib/debug_database.dart
Future<void> main() async {
  // Initialize FFI for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  print('╔════════════════════════════════════════════════════════════════╗');
  print('║          DATABASE DEBUG TOOL - Tailor App                      ║');
  print('╚════════════════════════════════════════════════════════════════╝\n');

  try {
    // Get database path
    final databasePath = await getDatabasesPath();
    final dbName = AppConfig.databaseName;
    final fullPath = join(databasePath, dbName);

    print('📍 DATABASE LOCATION:');
    print('   Path: $databasePath');
    print('   Name: $dbName');
    print('   Full Path: $fullPath');
    print('');

    // Check if database exists
    final dbFile = File(fullPath);
    if (await dbFile.exists()) {
      final stats = await dbFile.stat();
      print('✅ Database file exists!');
      print('   Size: ${(stats.size / 1024).toStringAsFixed(2)} KB');
      print('   Modified: ${stats.modified}');
    } else {
      print('❌ Database file does NOT exist!');
      print('   You may need to run the app first to create it.');
      return;
    }
    print('');

    // Open database
    print('🔓 Opening database...');
    final db = await openDatabase(fullPath);
    final version = await db.getVersion();
    print('   Database Version: $version');
    print('');

    // Get tailor table schema
    print('📋 TAILOR TABLE SCHEMA:');
    print('─────────────────────────────────────────────────────────────────');
    final tableInfo = await db.rawQuery("PRAGMA table_info(tailor)");
    
    if (tableInfo.isEmpty) {
      print('❌ Tailor table does not exist!');
    } else {
      print('Column Name          Type            Null?  Default  Primary');
      print('─────────────────────────────────────────────────────────────────');
      for (var column in tableInfo) {
        final name = (column['name'] as String).padRight(20);
        final type = (column['type'] as String).padRight(15);
        final notNull = column['notnull'] == 1 ? 'NO ' : 'YES';
        final defaultValue = (column['dflt_value']?.toString() ?? 'NULL').padRight(8);
        final pk = column['pk'] == 1 ? 'YES' : 'NO';
        print('$name $type $notNull    $defaultValue $pk');
      }
    }
    print('');

    // Get indexes
    print('🔑 INDEXES ON TAILOR TABLE:');
    print('─────────────────────────────────────────────────────────────────');
    final indexes = await db.rawQuery(
      "SELECT name, sql FROM sqlite_master WHERE type='index' AND tbl_name='tailor'"
    );
    
    if (indexes.isEmpty) {
      print('   No indexes found');
    } else {
      for (var index in indexes) {
        print('   ${index['name']}');
        if (index['sql'] != null) {
          print('   ${index['sql']}');
        }
        print('');
      }
    }

    // Count records
    print('📊 TAILOR TABLE DATA:');
    print('─────────────────────────────────────────────────────────────────');
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tailor')
    ) ?? 0;
    final activeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tailor WHERE is_active = 1')
    ) ?? 0;
    final inactiveCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tailor WHERE is_active = 0')
    ) ?? 0;
    final deletedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tailor WHERE is_deleted = 1')
    ) ?? 0;

    print('   Total Records: $totalCount');
    print('   Active Users:  $activeCount (is_active = 1)');
    print('   Inactive Users: $inactiveCount (is_active = 0)');
    print('   Deleted Users: $deletedCount (is_deleted = 1)');
    print('');

    // Show sample records
    if (totalCount > 0) {
      print('📄 SAMPLE RECORDS (last 5):');
      print('─────────────────────────────────────────────────────────────────');
      final records = await db.rawQuery(
        'SELECT id, unique_id, name, email, is_active, is_deleted, created_at FROM tailor ORDER BY created_at DESC LIMIT 5'
      );
      
      for (var record in records) {
        print('\n   ID: ${record['id']}');
        print('   Unique ID: ${record['unique_id']}');
        print('   Name: ${record['name']}');
        print('   Email: ${record['email']}');
        print('   Active: ${record['is_active'] == 1 ? '✅ YES' : '❌ NO'}');
        print('   Deleted: ${record['is_deleted'] == 1 ? '🗑️ YES' : '✅ NO'}');
        print('   Created: ${record['created_at']}');
      }
    } else {
      print('   No records found in tailor table');
    }
    print('');

    // Check for users with specific states
    print('🔍 USER STATES:');
    print('─────────────────────────────────────────────────────────────────');
    
    // Active users
    final activeUsers = await db.rawQuery(
      'SELECT email, name FROM tailor WHERE is_active = 1 AND is_deleted = 0'
    );
    print('   Active & Verified Users: ${activeUsers.length}');
    for (var user in activeUsers) {
      print('      - ${user['name']} (${user['email']})');
    }
    
    // Inactive users (not verified OTP)
    final inactiveUsers = await db.rawQuery(
      'SELECT email, name FROM tailor WHERE is_active = 0 AND is_deleted = 0'
    );
    print('\n   Inactive (Pending OTP) Users: ${inactiveUsers.length}');
    for (var user in inactiveUsers) {
      print('      - ${user['name']} (${user['email']})');
    }
    print('');

    // Check all tables in database
    print('📚 ALL TABLES IN DATABASE:');
    print('─────────────────────────────────────────────────────────────────');
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
    );
    for (var table in tables) {
      final tableName = table['name'];
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName')
      ) ?? 0;
      print('   ${tableName.toString().padRight(20)} ($count records)');
    }
    print('');

    await db.close();
    print('✅ Database inspection complete!');

  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }

  print('\n╚════════════════════════════════════════════════════════════════╝');
}
