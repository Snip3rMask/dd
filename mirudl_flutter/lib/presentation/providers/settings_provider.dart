import 'package:flutter/foundation.dart';

import '../../data/repositories/settings_repository.dart';

/// ViewModel for the Settings screen
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  String? _folderPath;
  int _parallel;
  String _quality;
  String _language;

  SettingsProvider(this._repository)
      : _parallel = 16,
        _quality = '1080p',
        _language = 'jpn' {
    loadSettings();
  }

  String? get folderPath => _folderPath;
  int get parallel => _parallel;
  String get quality => _quality;
  String get language => _language;
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
}
