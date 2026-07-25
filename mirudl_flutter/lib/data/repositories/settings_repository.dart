import '../datasources/local/storage_helper.dart';

/// Repository for app settings
class SettingsRepository {
  final StorageHelper _storage;

  SettingsRepository(this._storage);

  // --- Download URI ---

  String? getDownloadUri() => _storage.getDownloadUri();
  Future<void> setDownloadUri(String uri) => _storage.setDownloadUri(uri);
  bool hasDownloadUri() => _storage.hasDownloadUri();

  // --- Parallel Segments ---

  int getParallelSegments() => _storage.getParallelSegments();
  Future<void> setParallelSegments(int value) =>
      _storage.setParallelSegments(value);

  // --- Quality ---

  String getPreferredQuality() => _storage.getPreferredQuality();
  Future<void> setPreferredQuality(String quality) =>
      _storage.setPreferredQuality(quality);

  // --- Language ---

  String getPreferredLanguage() => _storage.getPreferredLanguage();
  Future<void> setPreferredLanguage(String language) =>
      _storage.setPreferredLanguage(language);

  // --- Dark Mode ---

  bool getDarkMode() => _storage.getDarkMode();
  Future<void> setDarkMode(bool value) => _storage.setDarkMode(value);
}
