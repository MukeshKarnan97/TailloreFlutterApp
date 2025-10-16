import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data/services/local_db_service.dart';

/// Quick script to verify password hashes in database
Future<void> main() async {
  print('🔍 Checking password hashes in database...\n');
  
  try {
    final dbService = LocalDbService();
    await dbService.initDatabase();
    
    final results = await dbService.select(
      'tailor',
      where: 'is_deleted = 0',
    );
    
    if (results.isEmpty) {
      print('❌ No users found in database');
      return;
    }
    
    print('📊 User Accounts:\n');
    print('=' * 80);
    
    for (var user in results) {
      final email = user['email'];
      final passwordHash = user['password_hash'] ?? '';
      final isActive = user['is_active'] == 1;
      final hashLength = passwordHash.length;
      
      print('Email: $email');
      print('Active: ${isActive ? "✅ Yes" : "❌ No"}');
      print('Password Hash Length: $hashLength characters');
      
      if (hashLength == 0) {
        print('⚠️  WARNING: Password hash is EMPTY! User cannot sign in.');
      } else if (hashLength == 64) {
        print('✅ Password hash looks valid (SHA256 = 64 chars)');
        print('   Hash preview: ${passwordHash.substring(0, 16)}...');
      } else {
        print('⚠️  WARNING: Unexpected hash length (expected 64 for SHA256)');
        print('   Hash: $passwordHash');
      }
      
      print('-' * 80);
    }
    
    print('\n💡 Notes:');
    print('   - SHA256 produces 64 character hexadecimal strings');
    print('   - Empty password_hash means user cannot sign in');
    print('   - Re-register if password hash is empty\n');
    
  } catch (e) {
    print('❌ Error checking database: $e');
  }
}
