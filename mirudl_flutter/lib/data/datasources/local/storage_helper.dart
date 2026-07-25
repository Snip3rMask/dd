import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// SharedPreferences wrapper (mirrors StorageSettings.java)
class StorageHelper {
  static const String _keyDownloadUri = 'download_uri';
  static const String _keyParallel = 'parallel_segments';
  static const String _keyQuality = 'preferred_quality';
  static const String _keyLanguage = 'preferred_language';
  static const String _keyDarkMode = 'dark_mode';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError('StorageHelper not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // --- Download URI ---

  String? getDownloadUri() {
    return _p.getString(_keyDownloadUri);
  }

  Future<void> setDownloadUri(String uri) async {
    await _p.setString(_keyDownloadUri, uri);
  }

  bool hasDownloadUri() {
    final uri = getDownloadUri();
    return uri != null && uri.isNotEmpty;
  }

  // --- Parallel Segments ---

  int getParallelSegments() {
    return _p.getInt(_keyParallel) ?? AppConstants.defaultParallel;
  }

  Future<void> setParallelSegments(int value) async {
    await _p.setInt(_keyParallel, value);
  }

  // --- Preferred Quality ---

  String getPreferredQuality() {
    return _p.getString(_keyQuality) ?? AppConstants.defaultQuality;
  }

  Future<void> setPreferredQuality(String quality) async {
    await _p.setString(_keyQuality, quality);
  }

  // --- Preferred Language ---

  String getPreferredLanguage() {
    return _p.getString(_keyLanguage) ?? AppConstants.defaultLanguage;
  }

  Future<void> setPreferredLanguage(String language) async {
    await _p.setString(_keyLanguage, language);
  }

  // --- Dark Mode ---

  bool getDarkMode() {
    return _p.getBool(_keyDarkMode) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    await _p.setBool(_keyDarkMode, value);
  }
}
