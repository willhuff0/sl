import 'dart:async';
import 'dart:collection';

enum LogSeverity {
  error,
  warning,
  info,
  debug,
}

class Log {
  final String message;
  final DateTime timestamp;
  final LogSeverity severity;

  Log({
    required this.message,
    required this.timestamp,
    required this.severity,
  });
}

class Logger {
  static var _maxLogs = 100;
  static final List<Log> _logs = [];
  static final StreamController<Log?> _logController = .broadcast();
  static final Stream<Log?> _logStream = _logController.stream;

  static void log(String message, [LogSeverity severity = .debug]) {
    if (_logs.length > _maxLogs) _logs.removeLast();
    _logs.insert(
      0,
      Log(
        message: message,
        timestamp: DateTime.now(),
        severity: severity,
      ),
    );
    _logController.add(_logs.last);
  }

  static void setMaxLogs(int maxLogs) {
    _maxLogs = maxLogs;
  }

  static void clear() {
    _logs.clear();
    _logController.add(null);
  }

  static int getLogCount() {
    return _logs.length;
  }

  static UnmodifiableListView<Log> getLogs() {
    return UnmodifiableListView(_logs);
  }

  static Stream<Log?> getStream() {
    return _logStream;
  }
}
