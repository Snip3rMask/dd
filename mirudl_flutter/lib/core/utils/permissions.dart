import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Cross-platform permission helper
class AppPermissions {
  /// Check and request storage permissions for downloading
  /// Returns true if permission granted
  static Future<bool> requestStorage() async {
    if (Platform.isAndroid) {
      return await _requestAndroidStorage();
    }
    // Desktop (Windows/Linux/macOS) — no runtime permission needed
    return true;
  }

  static Future<bool> _requestAndroidStorage() async {
    // Android 13+ (API 33+): Use granular media permissions
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Try MANAGE_EXTERNAL_STORAGE first (Android 11+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // Fallback: request storage permissions
    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // If denied but not permanently, show rationale
    if (status.isDenied) {
      status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    return false;
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ needs POST_NOTIFICATIONS
      if (await Permission.notification.isGranted) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Show rationale dialog for permission
  static Future<bool> showPermissionRationale(
    String title,
    String message,
  ) async {
    // This would be called from UI context — for now return false
    // Actual dialog is handled in the settings/download screen
    return false;
  }
}
