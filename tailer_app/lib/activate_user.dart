import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'data/services/local_db_service.dart';

/// Manually activate a user account (set is_active = 1)
/// Run this with: flutter run lib/activate_user.dart
void main() async {
  runApp(const ActivateUserApp());
}

class ActivateUserApp extends StatelessWidget {
  const ActivateUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activate User',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ActivateUserScreen(),
    );
  }
}

class ActivateUserScreen extends StatefulWidget {
  const ActivateUserScreen({super.key});

  @override
  State<ActivateUserScreen> createState() => _ActivateUserScreenState();
}

class _ActivateUserScreenState extends State<ActivateUserScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'mukesh.dmc97@gmail.com', // Default email
  );
  
  String _status = 'Enter email to activate';
  List<String> _logs = [];
  bool _isProcessing = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      _status = message;
    });
    print(message);
  }

  Future<void> _loadAllUsers() async {
    try {
      _addLog('📋 Loading all users...');
      
      final dbService = LocalDatabaseService();
      final db = await dbService.database;
      
      final users = await db.query(
        'tailor',
        orderBy: 'created_at DESC',
      );
      
      setState(() {
        _users = users;
      });
      
      _addLog('✅ Found ${users.length} user(s)');
      
      for (final user in users) {
        _addLog('  • ${user['email']} - Active: ${user['is_active']} - Deleted: ${user['is_deleted']}');
      }
    } catch (e) {
      _addLog('❌ Error loading users: $e');
    }
  }

  Future<void> _activateUser() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _addLog('❌ Please enter an email address');
      return;
    }

    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    try {
      _addLog('🔧 Activating user: $email');
      _addLog('═' * 50);

      final dbService = LocalDatabaseService();
      final db = await dbService.database;

      // Check if user exists
      final existing = await db.query(
        'tailor',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existing.isEmpty) {
        _addLog('❌ User not found: $email');
        _addLog('\\n💡 Available users:');
        final allUsers = await db.query('tailor');
        for (final user in allUsers) {
          _addLog('  • ${user['email']}');
        }
        return;
      }

      final user = existing.first;
      _addLog('✅ User found!');
      _addLog('  Name: ${user['name']}');
      _addLog('  Email: ${user['email']}');
      _addLog('  Current is_active: ${user['is_active']}');
      _addLog('  Current is_deleted: ${user['is_deleted']}');

      // Update is_active to 1
      final updated = await db.update(
        'tailor',
        {'is_active': 1, 'is_deleted': 0},
        where: 'email = ?',
        whereArgs: [email],
      );

      if (updated > 0) {
        _addLog('\\n✅ User activated successfully!');

        // Verify update
        final verified = await db.query(
          'tailor',
          where: 'email = ?',
          whereArgs: [email],
        );

        if (verified.isNotEmpty) {
          final updatedUser = verified.first;
          _addLog('\\n📋 Updated user details:');
          _addLog('  Email: ${updatedUser['email']}');
          _addLog('  Name: ${updatedUser['name']}');
          _addLog('  is_active: ${updatedUser['is_active']} ✅');
          _addLog('  is_deleted: ${updatedUser['is_deleted']} ✅');
          _addLog('\\n🎉 User can now log in!');
        }

        // Reload all users
        await _loadAllUsers();
      } else {
        _addLog('❌ Failed to update user');
      }

    } catch (e, stackTrace) {
      _addLog('\\n❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _activateAll() async {
    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    try {
      _addLog('🔧 Activating ALL users...');
      
      final dbService = LocalDatabaseService();
      final db = await dbService.database;

      final updated = await db.update(
        'tailor',
        {'is_active': 1, 'is_deleted': 0},
        where: 'is_deleted = 0',
      );

      _addLog('✅ Activated $updated user(s)');
      
      await _loadAllUsers();
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activate User Account'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isProcessing ? Colors.orange : Colors.blue,
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

          // Input section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter email to activate',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _activateUser,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Activate User'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _activateAll,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Activate All'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users list
          if (_users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Users:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._users.map((user) => Card(
                    child: ListTile(
                      leading: Icon(
                        user['is_active'] == 1 
                          ? Icons.check_circle 
                          : Icons.cancel,
                        color: user['is_active'] == 1 
                          ? Colors.green 
                          : Colors.red,
                      ),
                      title: Text(user['email'] as String),
                      subtitle: Text(
                        'Active: ${user['is_active']} | Deleted: ${user['is_deleted']}',
                      ),
                      onTap: () {
                        _emailController.text = user['email'] as String;
                      },
                    ),
                  )),
                ],
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
                } else if (log.contains('❌')) {
                  textColor = Colors.red;
                } else if (log.contains('⚠️')) {
                  textColor = Colors.orange;
                } else if (log.contains('🔧') || log.contains('📋')) {
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
