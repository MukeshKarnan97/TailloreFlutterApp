import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'data/services/local_db_service.dart';
import 'core/utils/logger.dart';

/// Force database creation and verification
/// Run this with: flutter run lib/force_database_creation.dart
void main() async {
  runApp(const DatabaseCreationApp());
}

class DatabaseCreationApp extends StatelessWidget {
  const DatabaseCreationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Creation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DatabaseCreationScreen(),
    );
  }
}

class DatabaseCreationScreen extends StatefulWidget {
  const DatabaseCreationScreen({super.key});

  @override
  State<DatabaseCreationScreen> createState() => _DatabaseCreationScreenState();
}

class _DatabaseCreationScreenState extends State<DatabaseCreationScreen> {
  String _status = 'Initializing...';
  List<String> _logs = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _createDatabase();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      _status = message;
    });
    print(message);
  }

  Future<void> _createDatabase() async {
    setState(() {
      _isCreating = true;
      _logs.clear();
    });

    try {
      _addLog('🔥 FORCE DATABASE CREATION');
      _addLog('═' * 50);

      // Get database path
      final dbPath = await getDatabasesPath();
      final fullPath = join(dbPath, 'tailor_app.db');
      _addLog('📍 Database path: $dbPath');
      _addLog('📄 Full path: $fullPath');

      // Check if database exists
      final dbFile = File(fullPath);
      final existsBefore = await dbFile.exists();
      _addLog(existsBefore 
        ? '⚠️ Database already exists' 
        : '❌ Database does NOT exist'
      );

      // Create database using LocalDatabaseService
      _addLog('\\n🔧 Creating database using LocalDatabaseService...');
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      _addLog('✅ Database instance obtained');

      // Verify database exists after creation
      final existsAfter = await dbFile.exists();
      _addLog(existsAfter 
        ? '✅ Database file NOW EXISTS!' 
        : '❌ Database file STILL MISSING!'
      );

      // Get database stats
      if (await dbFile.exists()) {
        final stats = await dbFile.stat();
        _addLog('💾 Database size: ${(stats.size / 1024).toStringAsFixed(2)} KB');
        _addLog('📅 Created: ${stats.modified}');
      }

      // Verify database version
      final version = await db.getVersion();
      _addLog('\\n📌 Database version: $version');

      // List all tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );

      _addLog('\\n📋 Tables in database (${tables.length}):');
      for (final table in tables) {
        final tableName = table['name'] as String;
        if (tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
          try {
            final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tableName')
            ) ?? 0;
            _addLog('  ✓ $tableName ($count records)');
          } catch (e) {
            _addLog('  ⚠ $tableName (error reading count)');
          }
        }
      }

      // Verify tailor table specifically
      _addLog('\\n👥 Checking tailor table...');
      try {
        final tailorSchema = await db.rawQuery('PRAGMA table_info(tailor)');
        _addLog('✅ Tailor table exists with ${tailorSchema.length} columns');
        
        // Check for is_active column
        final hasIsActive = tailorSchema.any((col) => col['name'] == 'is_active');
        _addLog(hasIsActive 
          ? '✅ is_active column EXISTS' 
          : '❌ is_active column MISSING'
        );

        // Count records
        final tailorCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tailor')
        ) ?? 0;
        _addLog('📊 Tailor records: $tailorCount');

        // Show all tailors
        if (tailorCount > 0) {
          final tailors = await db.rawQuery(
            'SELECT id, email, name, is_active, is_deleted FROM tailor LIMIT 5'
          );
          _addLog('\\n📋 Tailor records:');
          for (final tailor in tailors) {
            _addLog('  • ${tailor['email']} - Active: ${tailor['is_active']} - Deleted: ${tailor['is_deleted']}');
          }
        }
      } catch (e) {
        _addLog('❌ Error checking tailor table: $e');
      }

      // List all files in database folder
      _addLog('\\n📂 Files in databases folder:');
      final dbDir = Directory(dbPath);
      final files = await dbDir.list().toList();
      for (var file in files) {
        final fileName = basename(file.path);
        if (file is File) {
          final stats = await file.stat();
          _addLog('  📄 $fileName (${(stats.size / 1024).toStringAsFixed(2)} KB)');
        } else {
          _addLog('  📁 $fileName');
        }
      }

      _addLog('\\n✅ DATABASE IS READY!');
      _addLog('═' * 50);

    } catch (e, stackTrace) {
      _addLog('\\n❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Force Database Creation'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isCreating ? Colors.orange : Colors.green,
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black;
                
                if (log.contains('✅')) {
                  textColor = Colors.green;
                } else if (log.contains('❌') || log.contains('ERROR')) {
                  textColor = Colors.red;
                } else if (log.contains('⚠️')) {
                  textColor = Colors.orange;
                } else if (log.contains('🔥') || log.contains('🔧')) {
                  textColor = Colors.blue;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createDatabase,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recreate Database'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
