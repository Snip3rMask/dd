import 'package:flutter/foundation.dart';

import '../../data/repositories/settings_repository.dart';

/// ViewModel for the Settings screen
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  String? _folderPath;
  int _parallel;
  String _quality;
  String _language;
  bool _darkMode;

  SettingsProvider(this._repository)
      : _parallel = 16,
        _quality = '1080p',
        _language = 'jpn',
        _darkMode = true {
    loadSettings();
  }

  String? get folderPath => _folderPath;
  int get parallel => _parallel;
  String get quality => _quality;
  String get language => _language;
  bool get darkMode => _darkMode;
  bool get hasFolder => _folderPath != null;

  String get languageLabel {
    switch (_language) {
      case 'eng':
        return 'Dub (English)';
      default:
        return 'Sub (Japanese)';
    }
  }

  /// Load all settings from storage
  void loadSettings() {
    _folderPath = _repository.getDownloadUri();
    _parallel = _repository.getParallelSegments();
    _quality = _repository.getPreferredQuality();
    _language = _repository.getPreferredLanguage();
    _darkMode = _repository.getDarkMode();
    notifyListeners();
  }

  /// Set download folder URI
  Future<void> setFolderPath(String path) async {
    _folderPath = path;
    await _repository.setDownloadUri(path);
    notifyListeners();
  }

  /// Update parallel segments value
  Future<void> setParallel(int value) async {
    _parallel = value;
    await _repository.setParallelSegments(value);
    notifyListeners();
  }

  /// Update preferred quality
  Future<void> setQuality(String value) async {
    _quality = value;
    await _repository.setPreferredQuality(value);
    notifyListeners();
  }

  /// Update preferred language
  Future<void> setLanguage(String value) async {
    _language = value;
    await _repository.setPreferredLanguage(value);
    notifyListeners();
  }

  /// Toggle dark/light theme
  Future<void> toggleTheme() async {
    _darkMode = !_darkMode;
    await _repository.setDarkMode(_darkMode);
    notifyListeners();
  }
}
