import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

/// Database Debug Screen
/// Shows database path, table schema, and records
class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  String? dbPath;
  List<Map<String, dynamic>> tableSchema = [];
  List<Map<String, dynamic>> tableData = [];
  int totalRecords = 0;
  int activeRecords = 0;
  int inactiveRecords = 0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Get database path
      final databasePath = await getDatabasesPath();
      final fullPath = join(databasePath, 'tailor_app.db');
      
      setState(() {
        dbPath = fullPath;
      });

      // Open database
      final db = await openDatabase(fullPath);

      // Get table schema
      final schema = await db.rawQuery("PRAGMA table_info(tailor)");
      
      // Get record counts
      final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tailor')
      ) ?? 0;
      
      final active = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tailor WHERE is_active = 1')
      ) ?? 0;
      
      final inactive = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tailor WHERE is_active = 0')
      ) ?? 0;

      // Get sample data
      final data = await db.rawQuery(
        'SELECT id, unique_id, name, email, phone, is_active, is_deleted, created_at FROM tailor ORDER BY created_at DESC LIMIT 10'
      );

      await db.close();

      setState(() {
        tableSchema = schema;
        tableData = data;
        totalRecords = total;
        activeRecords = active;
        inactiveRecords = inactive;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatabaseInfo,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDatabaseInfo,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Database Path',
                        Text(
                          dbPath ?? 'Unknown',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFileInfo(),
                      const SizedBox(height: 16),
                      _buildRecordCounts(),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Table Schema',
                        _buildSchemaTable(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Sample Records (Last 10)',
                        _buildDataTable(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    if (dbPath == null) return const SizedBox();

    final file = File(dbPath!);
    
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final exists = snapshot.data!;
        
        return Card(
          color: exists ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      exists ? Icons.check_circle : Icons.cancel,
                      color: exists ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      exists ? 'Database Exists' : 'Database Not Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: exists ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (exists)
                  FutureBuilder<FileStat>(
                    future: file.stat(),
                    builder: (context, statSnapshot) {
                      if (!statSnapshot.hasData) return const SizedBox();
                      
                      final stat = statSnapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Size: ${(stat.size / 1024).toStringAsFixed(2)} KB'),
                          Text('Modified: ${stat.modified}'),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordCounts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatRow('Total Records', totalRecords, Colors.blue),
            _buildStatRow('Active Users (is_active=1)', activeRecords, Colors.green),
            _buildStatRow('Inactive Users (is_active=0)', inactiveRecords, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaTable() {
    if (tableSchema.isEmpty) {
      return const Text('No schema information available');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Column')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Not Null')),
          DataColumn(label: Text('Default')),
          DataColumn(label: Text('PK')),
        ],
        rows: tableSchema.map((column) {
          return DataRow(
            cells: [
              DataCell(Text(
                column['name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(Text(column['type'].toString())),
              DataCell(Icon(
                column['notnull'] == 1 ? Icons.check : Icons.close,
                size: 16,
                color: column['notnull'] == 1 ? Colors.green : Colors.grey,
              )),
              DataCell(Text(column['dflt_value']?.toString() ?? '-')),
              DataCell(Icon(
                column['pk'] == 1 ? Icons.key : Icons.close,
                size: 16,
                color: column['pk'] == 1 ? Colors.amber : Colors.grey,
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataTable() {
    if (tableData.isEmpty) {
      return const Text('No records found');
    }

    return Column(
      children: tableData.map((record) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordField('ID', record['id']),
                _buildRecordField('Unique ID', record['unique_id']),
                _buildRecordField('Name', record['name']),
                _buildRecordField('Email', record['email']),
                _buildRecordField('Phone', record['phone']),
                Row(
                  children: [
                    Icon(
                      record['is_active'] == 1 ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: record['is_active'] == 1 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record['is_active'] == 1 ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: record['is_active'] == 1 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (record['is_deleted'] == 1) ...[
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text(
                        'Deleted',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
                _buildRecordField('Created', record['created_at']),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecordField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'null',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
