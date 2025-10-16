/// Quick Database Check Button
/// 
/// Add this floating action button to any screen to quickly check local database
/// 
/// Usage:
/// ```dart
/// Scaffold(
///   floatingActionButton: QuickDbCheckButton(), // ← Add this
///   body: ...
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:tailer_app/utils/check_local_db.dart';

class QuickDbCheckButton extends StatelessWidget {
  const QuickDbCheckButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await checkLocalDatabase();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Database checked! See console for details.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      icon: const Icon(Icons.storage),
      label: const Text('Check DB'),
      backgroundColor: Colors.deepPurple,
      tooltip: 'Check Local Database Contents',
    );
  }
}
