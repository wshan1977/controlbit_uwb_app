import 'dart:convert';

import '../models/ranging_sample.dart';

class LogEntry {
  const LogEntry({
    required this.timestampMs,
    required this.level,
    required this.tag,
    required this.message,
  });

  final int timestampMs;
  final String level;
  final String tag;
  final String message;

  Map<String, dynamic> toJson() => {
        't': timestampMs,
        'l': level,
        'tag': tag,
        'msg': message,
      };
}

class LogService {
  LogService({this.capacity = 1000});

  final int capacity;
  final List<LogEntry> _entries = [];
  final List<RangingSample> _samples = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);
  List<RangingSample> get samples => List.unmodifiable(_samples);

  void info(String tag, String message) => _push('INFO', tag, message);
  void warn(String tag, String message) => _push('WARN', tag, message);
  void error(String tag, String message) => _push('ERROR', tag, message);

  void recordSample(RangingSample s) {
    _samples.add(s);
    if (_samples.length > capacity) {
      _samples.removeRange(0, _samples.length - capacity);
    }
  }

  void clear() {
    _entries.clear();
    _samples.clear();
  }

  String exportJson() => jsonEncode({
        'log': _entries.map((e) => e.toJson()).toList(),
        'samples': _samples.map((s) => s.toJson()).toList(),
      });

  void _push(String level, String tag, String message) {
    _entries.add(LogEntry(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      level: level,
      tag: tag,
      message: message,
    ));
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
  }
}
