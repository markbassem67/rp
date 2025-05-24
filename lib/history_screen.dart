import 'package:flutter/material.dart';
import 'package:rp/detection_record.dart';


class HistoryScreen extends StatelessWidget {
  final List<DetectionRecord> history;
  final VoidCallback onClearHistory;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Start New Session',
            onPressed: () {
              _showConfirmDialog(context);
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text("No detections yet."))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final record = history[index];
          return ListTile(
            leading: const Icon(Icons.face),
            title: Text(record.name),
            subtitle: Text(
              '${record.timestamp.toLocal()}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Session?'),
        content: const Text('This will erase all detection history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onClearHistory(); // call the passed function
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session reset')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}


