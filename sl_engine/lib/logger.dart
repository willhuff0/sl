import 'dart:async';
import 'dart:collection';
import 'dart:math';

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
  int count;

  Log({
    required this.message,
    required this.timestamp,
    required this.severity,
    this.count = 1,
  });
  Log.copy(Log other) : message = other.message, timestamp = other.timestamp, severity = other.severity, count = other.count;

  bool canCollapseWith(String otherMessage, LogSeverity otherSeverity) {
    return message == otherMessage && severity == otherSeverity;
  }
}

class Logger {
  static var _maxLogs = 100;
  static final List<Log> _logs = [];
  static final StreamController<Log?> _logController = .broadcast();
  static final Stream<Log?> _logStream = _logController.stream;
  static var _collapse = true;

  static void log(String message, [LogSeverity severity = .debug]) {
    message = message.trim();

    if (_collapse && _logs.isNotEmpty && _logs.first.canCollapseWith(message, severity)) {
      _logs.first.count++;
      return;
    }

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
    print('[SL ${severity.name}] $message');
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

  static bool isCollapse() {
    return _collapse;
  }

  static void setCollapse(bool collapse) {
    if (_collapse == collapse) return;
    _collapse = collapse;

    if (_collapse) {
      for (int i = _logs.length - 1; i >= 1; i--) {
        if (!_logs[i - 1].canCollapseWith(_logs[i].message, _logs[i].severity)) continue;
        _logs[i - 1].count += _logs[i].count;
        _logs.removeAt(i);
      }
    } else {
      for (int i = _logs.length - 1; i >= 0 && _logs.length < _maxLogs; i--) {
        final log = _logs[i];
        if (log.count <= 1) continue;
        final count = log.count;
        log.count = 1;
        _logs.insertAll(i + 1, List.generate(min(count - 1, _maxLogs - _logs.length), (_) => Log.copy(log)));
      }
    }

    _logController.add(null);
  }
}
