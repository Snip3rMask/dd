import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Represents a single crash/error entry
class CrashEntry {
  final String id;
  final String timestamp;
  final String exceptionType;
  final String exceptionMessage;
  final String stackTrace;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final String screenName;

  CrashEntry({
    required this.id,
    required this.timestamp,
    required this.exceptionType,
    required this.exceptionMessage,
    required this.stackTrace,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.screenName,
  });

  /// Pretty-printed crash report as plain text
  String get formattedReport => '''
══════════════════════════════════════════════
            CRASH REPORT
══════════════════════════════════════════════

📱 DEVICE INFO
──────────────
  Device      : $deviceModel
  OS Version  : $osVersion
  App Version : $appVersion ($buildNumber)

🕐 WHEN
────────
  Timestamp   : $timestamp
  Screen      : $screenName

💥 EXCEPTION
─────────────
  Type  : $exceptionType
  Message: $exceptionMessage

📍 STACK TRACE
───────────────
$stackTrace

══════════════════════════════════════════════
''';

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'exceptionType': exceptionType,
        'exceptionMessage': exceptionMessage,
        'stackTrace': stackTrace,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'screenName': screenName,
      };

  factory CrashEntry.fromJson(Map<String, dynamic> json) {
    return CrashEntry(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      exceptionType: json['exceptionType'] as String? ?? '',
      exceptionMessage: json['exceptionMessage'] as String? ?? '',
      stackTrace: json['stackTrace'] as String? ?? '',
      deviceModel: json['deviceModel'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      buildNumber: json['buildNumber'] as String? ?? '',
      screenName: json['screenName'] as String? ?? '',
    );
  }
}

/// Advanced crash & error logging system
/// Captures app crashes with full context:
/// - Device info, OS, app version
/// - Timestamp, screen name
/// - Full exception type, message, stack trace
class Logger {
  static const String _crashDir = 'crash_logs';
  static Logger? _instance;

  String _appVersion = 'Unknown';
  String _buildNumber = 'Unknown';
  String _deviceModel = 'Unknown';
  String _osVersion = 'Unknown';
  bool _initialized = false;
  List<CrashEntry> _cache = [];

  /// Currently active screen for context tracking
  String currentScreen = 'Unknown';

  Logger._();

  static Logger get instance => _instance ??= Logger._();

  /// Initialize: collect device & app info
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('[Logger] Failed to get package info: $e');
    }

    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        _deviceModel = '${deviceInfo.brand} ${deviceInfo.model}';
        _osVersion =
            'Android ${deviceInfo.version.release} (API ${deviceInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final deviceInfo = await DeviceInfoPlugin().iosInfo;
        _deviceModel = '${deviceInfo.model} ${deviceInfo.name}';
        _osVersion = 'iOS ${deviceInfo.systemVersion}';
      } else {
        _deviceModel = Platform.operatingSystem;
        _osVersion = Platform.operatingSystemVersion;
      }
    } catch (e) {
      debugPrint('[Logger] Failed to get device info: $e');
    }

    // Load cached crash logs from disk
    await _loadCache();
  }

  // ─── Public API ──────────────────────────────────────────────

  /// Log a caught or uncaught exception
  Future<CrashEntry> logException(
    dynamic exception,
    StackTrace? stack, {
    String? screen,
  }) async {
    final entry = CrashEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now().toIso8601String(),
      exceptionType: exception.runtimeType.toString(),
      exceptionMessage: exception.toString(),
      stackTrace: stack?.toString() ?? 'No stack trace available',
      deviceModel: _deviceModel,
      osVersion: _osVersion,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
      screenName: screen ?? currentScreen,
    );

    // Save to file (with error reporting)
    await _saveToFile(entry);

    // Keep in memory cache
    _cache.insert(0, entry);
    if (_cache.length > 50) _cache = _cache.sublist(0, 50);

    // Also print to console
    debugPrint('[CRASH] ${entry.exceptionType}: ${entry.exceptionMessage}');

    return entry;
  }

  /// Get all crash logs (newest first)
  List<CrashEntry> getCrashLogs() => List.unmodifiable(_cache);

  /// Get the latest crash log, if any
  CrashEntry? get latestCrash => _cache.isNotEmpty ? _cache.first : null;

  /// Delete a specific crash log file
  Future<void> deleteCrashLog(CrashEntry entry) async {
    _cache.remove(entry);
    try {
      final file = await _getFile(entry.id);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[Logger] Failed to delete crash log: $e');
    }
  }

  /// Delete all crash logs
  Future<void> clearAll() async {
    _cache.clear();
    try {
      final dir = await getLogDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[Logger] Failed to clear crash logs: $e');
    }
  }

  /// Get the full file path for a crash log
  Future<String> getCrashLogPath(CrashEntry entry) async {
    final file = await _getFile(entry.id);
    return file.path;
  }

  /// Get the log directory
  Future<Directory> getLogDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_crashDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Simple debug log helper
  static void debug(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  // ─── Internal ────────────────────────────────────────────────

  Future<void> _saveToFile(CrashEntry entry) async {
    try {
      final dir = await getLogDirectory();
      final file = File('${dir.path}/crash_${entry.id}.txt');
      await file.writeAsString(entry.formattedReport);
      debugPrint('[Logger] Crash log saved: ${file.path}');
    } catch (e) {
      debugPrint('[Logger] FAILED to save crash log: $e');
      // Attempt fallback: write to app's temporary directory
      try {
        final tempDir = await getTemporaryDirectory();
        final fallbackFile =
            File('${tempDir.path}/crash_fallback_${entry.id}.txt');
        await fallbackFile.writeAsString(entry.formattedReport);
        debugPrint('[Logger] Fallback save: ${fallbackFile.path}');
      } catch (e2) {
        debugPrint('[Logger] Fallback save also failed: $e2');
      }
    }
  }

  Future<File> _getFile(String id) async {
    final dir = await getLogDirectory();
    return File('${dir.path}/crash_$id.txt');
  }

  Future<void> _loadCache() async {
    try {
      final dir = await getLogDirectory();
      if (!await dir.exists()) {
        debugPrint('[Logger] Crash log directory does not exist');
        return;
      }

      final files = await dir.list().toList();
      files.sort((a, b) => b.path.compareTo(a.path)); // newest first

      int loaded = 0;
      for (final entity in files.take(50)) {
        if (entity is File && entity.path.endsWith('.txt')) {
          try {
            final content = await entity.readAsString();
            final idMatch =
                RegExp(r'crash_(\d+)\.txt').firstMatch(entity.path);
            final id = idMatch?.group(1) ?? '';
            if (id.isNotEmpty) {
              _cache.add(CrashEntry(
                id: id,
                timestamp: _extractField(content, 'Timestamp'),
                exceptionType: _extractField(content, 'Type'),
                exceptionMessage: _extractField(content, 'Message'),
                stackTrace: _extractStackTrace(content),
                deviceModel: _extractField(content, 'Device'),
                osVersion: _extractField(content, 'OS Version'),
                appVersion: _extractField(content, 'App Version'),
                buildNumber: '',
                screenName: _extractField(content, 'Screen'),
              ));
              loaded++;
            }
          } catch (e) {
            debugPrint('[Logger] Failed to parse crash file: $e');
          }
        }
      }
      debugPrint('[Logger] Loaded $loaded crash log(s) from disk');
    } catch (e) {
      debugPrint('[Logger] Failed to load crash logs: $e');
    }
  }

  String _extractField(String content, String label) {
    final match = RegExp('$label\\s+: (.+)').firstMatch(content);
    return match?.group(1)?.trim() ?? 'Unknown';
  }

  String _extractStackTrace(String content) {
    final parts = content.split('STACK TRACE');
    if (parts.length > 1) {
      final stackPart = parts[1].split('══════════════════').first.trim();
      return stackPart;
    }
    return 'No stack trace';
  }
}
