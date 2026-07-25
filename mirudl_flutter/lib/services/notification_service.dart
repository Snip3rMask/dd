import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';

/// Notification service for download progress and alerts
/// Mirrors notification logic from DownloadService.java
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  /// Initialize notification channels
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDesc,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    _initialized = true;
  }

  /// Show download progress notification
  Future<void> showProgress({
    required int id,
    required String title,
    required String message,
    required int progress,
    bool indeterminate = false,
  }) async {
    await _plugin.show(
      id,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          ongoing: progress < 100,
          showProgress: !indeterminate,
          maxProgress: 100,
          progress: progress.clamp(0, 100),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Show a download complete notification
  Future<void> showComplete({
    required int id,
    required String title,
    required String message,
  }) async {
    await _plugin.show(
      id,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          onlyAlertOnce: true,
          ongoing: false,
          showProgress: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a download failure notification
  Future<void> showError({
    required int id,
    required String title,
    required String message,
  }) async {
    await _plugin.show(
      id,
      '❌ $title',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.high,
          onlyAlertOnce: true,
          ongoing: false,
          showProgress: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel a notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
