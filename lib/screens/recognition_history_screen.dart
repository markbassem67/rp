import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rp/provider.dart';
import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp) {
  return DateFormat('dd-MM-yyyy, hh:mm a').format(timestamp);
}

class RecognitionHistoryScreen extends StatelessWidget {
  const RecognitionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<RecognitionHistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Attendance'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash_fill),
            tooltip: "Clear History",
            onPressed: () {
              // Confirm clear action
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear History?',style: TextStyle(fontWeight: FontWeight.bold),),
                  content: const Text(
                      'Are you sure you want to clear the recognition history?',style: TextStyle(fontSize: 17),),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton(
                      onPressed: () {
                        historyProvider.clear();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Clear',style: TextStyle(color: Colors.red),),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: historyProvider.history.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(
                    child: Text(
                  'No saved attendance found',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                )),
                const SizedBox(
                  height: 25,
                ),
                ClipRRect(
                    borderRadius: BorderRadius.circular(35.0),
                    child: Image.asset(
                      'assets/noattendancefound.PNG',
                      scale: 3.2,
                    ))
              ],
            )
          : ListView.builder(
              itemCount: historyProvider.history.length,
              itemBuilder: (context, index) {
                final entry = historyProvider.history[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18, // size of the circle
                    backgroundColor: Colors.blue, // circle color
                    child: Text(
                      '${index + 1}', // show the index starting from 1
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  subtitle: Text(formatTimestamp(entry.timestamp)),
                );
              },
            ),
    );
  }
}
