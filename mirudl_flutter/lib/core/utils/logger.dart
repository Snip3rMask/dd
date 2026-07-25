import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

/// Logging utility that writes crash logs to file (like CrashLogger.java)
class Logger {
  static const String _crashDir = 'crash_logs';
  static Logger? _instance;

  Logger._();

  static Logger get instance => _instance ??= Logger._();

  /// Log an uncaught exception to file
  Future<void> logException(dynamic exception, StackTrace? stack) async {
    final dir = await getLogDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/crash_$timestamp.txt');

    try {
      await file.writeAsString('''=== CRASH REPORT ===
Time: $timestamp
Exception: $exception
Stack Trace:
$stack
''');
    } catch (_) {
      // Silently fail — can't log if logger itself fails
    }

    // Also print to console in debug
    // ignore: avoid_print
    print('[CRASH] $exception\n$stack');
  }

  /// Save a caught exception manually
  Future<void> saveCaughtException(dynamic exception, StackTrace? stack) async {
    await logException(exception, stack);
  }

  /// Get the log directory, creating it if needed
  Future<Directory> getLogDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_crashDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Simple debug log
  static void debug(String tag, String message) {
    // ignore: avoid_print
    print('[$tag] $message');
  }
}
