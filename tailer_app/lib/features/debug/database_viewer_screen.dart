import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Debug screen to view all tailor data from database
/// Shows unhashed passwords for debugging sign-in issues
class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  List<Map<String, dynamic>> _tailors = [];
  bool _isLoading = true;
  String? _error;
  String _dbPath = '';
  int _dbVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get database instance (lazy initialization)
      final db = await _dbService.database;
      
      // Get database info
      _dbPath = db.path;
      _dbVersion = await db.rawQuery('PRAGMA user_version').then((result) {
        return result.isNotEmpty ? result.first['user_version'] as int : 0;
      });

      // Load all tailor records
      final results = await _dbService.select(
        'tailor',
        orderBy: 'created_at DESC',
      );

      setState(() {
        _tailors = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Database Viewer'),
        backgroundColor: const Color(0xFF21899C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF21899C),
            ),
            SizedBox(height: 16),
            Text('Loading database...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Database',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21899C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Database Info Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Database Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Path', _dbPath),
              _buildInfoRow('Version', _dbVersion.toString()),
              _buildInfoRow('Total Records', _tailors.length.toString()),
            ],
          ),
        ),
        
        const Divider(height: 1),

        // Tailor Records List
        Expanded(
          child: _tailors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tailors.length,
                  itemBuilder: (context, index) {
                    return _buildTailorCard(_tailors[index], index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Users in Database',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register a user to see data here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTailorCard(Map<String, dynamic> tailor, int number) {
    final email = tailor['email']?.toString() ?? 'N/A';
    final name = tailor['name']?.toString() ?? 'N/A';
    final shopName = tailor['shop_name']?.toString() ?? 'N/A';
    final phone = tailor['phone']?.toString() ?? 'N/A';
    final passwordHash = tailor['password_hash']?.toString() ?? '';
    final isActive = (tailor['is_active'] as int?) == 1;
    final isDeleted = (tailor['is_deleted'] as int?) == 1;
    final authProvider = tailor['auth_provider']?.toString() ?? 'N/A';
    final createdAt = tailor['created_at']?.toString() ?? 'N/A';
    final id = tailor['id']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21899C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'User #$number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF21899C),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pending, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isDeleted)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Deleted',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // User Details
            _buildDetailRow(
              Icons.person,
              'Name',
              name,
              canCopy: true,
            ),
            _buildDetailRow(
              Icons.store,
              'Shop Name',
              shopName,
              canCopy: true,
            ),
            _buildDetailRow(
              Icons.email,
              'Email',
              email,
              canCopy: true,
            ),
            _buildDetailRow(
              Icons.phone,
              'Phone',
              phone,
              canCopy: true,
            ),
            _buildDetailRow(
              Icons.fingerprint,
              'ID',
              id,
              canCopy: true,
            ),
            _buildDetailRow(
              Icons.login,
              'Auth Provider',
              authProvider,
            ),
            _buildDetailRow(
              Icons.calendar_today,
              'Created',
              createdAt,
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Password Hash Section
            _buildPasswordHashSection(passwordHash, email: email),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool canCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (canCopy)
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyToClipboard(value, label),
            ),
        ],
      ),
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _testPassword(String passwordHash, String email) {
    final testPassword = 'Admin#234';
    final testHash = _hashPassword(testPassword);
    final matches = testHash == passwordHash;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              matches ? Icons.check_circle : Icons.cancel,
              color: matches ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Password Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: $email'),
            const SizedBox(height: 8),
            Text('Test Password: "$testPassword"'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: matches ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    matches ? Icons.check_circle : Icons.cancel,
                    color: matches ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      matches 
                        ? '✅ Password MATCHES!\nUser can sign in with this password.'
                        : '❌ Password does NOT match!\nHash mismatch or empty hash.',
                      style: TextStyle(
                        color: matches ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Hash Comparison:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Generated:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SelectableText(
              testHash,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
            const SizedBox(height: 8),
            Text('Stored:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SelectableText(
              passwordHash.isEmpty ? '(empty)' : passwordHash,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordHashSection(String passwordHash, {String? email}) {
    final hasHash = passwordHash.isNotEmpty;
    final hashLength = passwordHash.length;
    final isValidLength = hashLength == 64; // SHA256 produces 64 chars

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasHash
            ? (isValidLength ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05))
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasHash
              ? (isValidLength ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3))
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasHash ? Icons.lock : Icons.lock_open,
                size: 18,
                color: hasHash
                    ? (isValidLength ? Colors.green : Colors.orange)
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'Password Hash',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Length: $hashLength',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (!hasHash)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ EMPTY - User cannot sign in!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!isValidLength)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Invalid length (expected 64 for SHA256)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Valid SHA256 hash',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (hasHash) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      passwordHash,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyToClipboard(passwordHash, 'Password hash'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Test Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _testPassword(passwordHash, email ?? 'Unknown'),
                icon: const Icon(Icons.password, size: 18),
                label: const Text('Test Password: "Admin#234"'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21899C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
