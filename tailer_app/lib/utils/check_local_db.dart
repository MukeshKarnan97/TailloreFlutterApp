import 'package:flutter/material.dart';
import 'package:tailer_app/data/services/local_db_service.dart';

/// Quick script to check local database content
/// Run this to verify if registration data is being saved locally
Future<void> checkLocalDatabase() async {
  debugPrint('========================================');
  debugPrint('CHECKING LOCAL DATABASE...');
  debugPrint('========================================');
  
  final db = LocalDatabaseService();
  
  try {
    // Get all tailors from local DB
    final tailors = await db.select('tailor');
    
    debugPrint('\n📊 TOTAL TAILORS IN LOCAL DB: ${tailors.length}');
    debugPrint('========================================\n');
    
    if (tailors.isEmpty) {
      debugPrint('❌ NO TAILORS FOUND IN LOCAL DATABASE');
      debugPrint('   This means registration is not syncing to local DB');
    } else {
      debugPrint('✅ TAILORS FOUND IN LOCAL DATABASE:\n');
      
      for (var i = 0; i < tailors.length; i++) {
        final tailor = tailors[i];
        debugPrint('👤 TAILOR #${i + 1}:');
        debugPrint('   ID: ${tailor['id']}');
        debugPrint('   Name: ${tailor['name']}');
        debugPrint('   Shop: ${tailor['shop_name']}');
        debugPrint('   Email: ${tailor['email']}');
        debugPrint('   Phone: ${tailor['phone'] ?? 'N/A'}');
        debugPrint('   Auth Provider: ${tailor['auth_provider']}');
        debugPrint('   Created: ${tailor['created_at']}');
        debugPrint('   Updated: ${tailor['updated_at']}');
        debugPrint('   Is Deleted: ${tailor['is_deleted']}');
        debugPrint('');
      }
    }
    
    debugPrint('========================================');
    debugPrint('DATABASE CHECK COMPLETE');
    debugPrint('========================================');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR CHECKING DATABASE:');
    debugPrint('   Error: $e');
    debugPrint('   Stack trace: $stackTrace');
  }
}

/// Widget to trigger database check with a button
class DatabaseCheckScreen extends StatelessWidget {
  const DatabaseCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Check'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storage,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Check Local Database',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the button below to check\nif registration data is saved locally',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await checkLocalDatabase();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Check console for database contents'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Check Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Results will appear in the console/logs',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
