import 'package:flutter/material.dart';
import 'data/services/local_db_service.dart';
import 'core/utils/logger.dart';

void main() {
  runApp(const DatabaseCheckApp());
}

class DatabaseCheckApp extends StatelessWidget {
  const DatabaseCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Checker',
      home: const DatabaseCheckScreen(),
    );
  }
}

class DatabaseCheckScreen extends StatefulWidget {
  const DatabaseCheckScreen({super.key});

  @override
  State<DatabaseCheckScreen> createState() => _DatabaseCheckScreenState();
}

class _DatabaseCheckScreenState extends State<DatabaseCheckScreen> {
  final List<String> _logs = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.add('${isError ? "❌" : "✅"} $message');
    });
    print(message);
  }

  Future<void> _checkDatabase() async {
    setState(() {
      _isChecking = true;
      _logs.clear();
    });

    try {
      _addLog('Starting database check...');
      
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      
      _addLog('Database opened successfully');
      _addLog('Database path: ${await db.getPath()}');
      
      // Check tailor table
      _addLog('\n📊 TAILOR TABLE:');
      final tailors = await db.query('tailor');
      _addLog('Total tailors: ${tailors.length}');
      
      for (var i = 0; i < tailors.length; i++) {
        final tailor = tailors[i];
        _addLog('\nTailor #${i + 1}:');
        _addLog('  • ID: ${tailor['id']}');
        _addLog('  • Email: ${tailor['email']}');
        _addLog('  • Name: ${tailor['name']}');
        _addLog('  • Shop: ${tailor['shop_name']}');
        _addLog('  • is_active: ${tailor['is_active']}');
        _addLog('  • Auth Provider: ${tailor['auth_provider']}');
        _addLog('  • Password Hash: ${tailor['password_hash']?.substring(0, 20) ?? 'NULL'}...');
      }
      
      // Check database stats
      _addLog('\n📊 DATABASE STATISTICS:');
      final stats = await dbService.getDatabaseStats();
      stats.forEach((table, count) {
        _addLog('  • $table: $count records');
      });
      
      _addLog('\n✅ Database check completed!');
      
    } catch (e, stackTrace) {
      _addLog('Error: $e', isError: true);
      Logger.error('DatabaseCheck', 'Failed to check database', 
        error: e, stackTrace: stackTrace);
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Checker'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          if (_isChecking)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.startsWith('❌');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isError ? Colors.red : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Refresh Check', 
                style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
