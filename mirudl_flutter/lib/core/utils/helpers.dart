import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Format file size in human-readable format
  /// e.g., 1.5 MB, 2.3 GB
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024.0 * 1024.0 * 1024.0)).toStringAsFixed(1)} GB';
  }

  /// Format timestamp to readable date
  static String formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Remove invalid filename characters
  static String sanitizeFileName(String value) {
    if (value.isEmpty) return 'Unknown';
    // Replace invalid chars with space
    final cleaned = value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > 80 ? cleaned.substring(0, 80).trim() : cleaned;
  }

  /// Extract anime name from "Title - Episode X" format
  static String extractParentName(String fileName) {
    final idx = fileName.indexOf(' - Episode');
    return idx > 0 ? fileName.substring(0, idx) : fileName;
  }

  /// Resolve a potentially relative URL against a base URL
  static String resolveUrl(String value, String base) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      final slash = base.indexOf('/', 8);
      return '${slash > 0 ? base.substring(0, slash) : base}$value';
    }
    final slash = base.lastIndexOf('/');
    return '${slash > 0 ? base.substring(0, slash + 1) : base}$value';
  }

  /// Extract resolution string from EXT-X-STREAM-INF line
  static String extractResolution(String infLine) {
    final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(infLine);
    if (resMatch != null) return resMatch.group(1)!;

    final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(infLine);
    if (bwMatch != null) return '${bwMatch.group(1)}bps';

    return 'Auto';
  }
}
