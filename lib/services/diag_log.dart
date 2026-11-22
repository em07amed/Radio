import 'package:flutter/foundation.dart';

/// Small in-memory log of app events and errors for the diagnostics screen.
class DiagLog {
  static final List<String> _lines = [];

  static void add(String msg) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    _lines.add('$t  $msg');
    if (_lines.length > 300) _lines.removeAt(0);
    debugPrint('[radio] $msg');
  }

  static String dump() => _lines.join('\n');
}
