import 'package:flutter/foundation.dart';

class RecognitionEntry {
  final String name;
  final DateTime timestamp;

  RecognitionEntry({required this.name, required this.timestamp});
}

class RecognitionHistoryProvider extends ChangeNotifier {
  final List<RecognitionEntry> _history = [];

  List<RecognitionEntry> get history => List.unmodifiable(_history);

  void addEntry(RecognitionEntry entry) {
    _history.add(entry);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }
}
