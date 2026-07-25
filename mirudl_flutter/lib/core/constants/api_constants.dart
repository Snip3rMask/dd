class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://anidb.app';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      'Chrome/120.0.0.0 Safari/537.36';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 30);

  // Endpoints
  static const String searchEndpoint = '/search/suggestions';
  static const String animeApiEndpoint = '/api/frontend/anime';
  static const String episodeApiEndpoint = '/api/frontend/episode';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'User-Agent': userAgent,
    'Referer': '$baseUrl/',
  };

  static const Map<String, String> jsonHeaders = {
    'User-Agent': userAgent,
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': '$baseUrl/',
  };

  static const Map<String, String> htmlHeaders = {
    'User-Agent': userAgent,
    'Accept': 'text/html,*/*',
    'Referer': '$baseUrl/',
  };
}
