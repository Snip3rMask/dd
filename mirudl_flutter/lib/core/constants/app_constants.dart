class AppConstants {
  AppConstants._();

  static const int defaultParallel = 16;
  static const int maxParallel = 32;

  static const List<String> qualities = [
    '1080p',
    '720p',
    '480p',
    '360p',
    'Auto',
  ];

  static const Map<String, String> languages = {
    'jpn': 'Sub (Japanese)',
    'eng': 'Dub (English)',
  };

  static const String defaultQuality = '1080p';
  static const String defaultLanguage = 'jpn';

  static const String notificationChannelId = 'mirudl_downloads';
  static const String notificationChannelName = 'Downloads';
  static const String notificationChannelDesc =
      'Download progress notifications';

  static const int notificationId = 1001;
}
