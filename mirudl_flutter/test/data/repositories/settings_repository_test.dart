import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/repositories/settings_repository.dart';
import 'package:mirudl_flutter/data/datasources/local/storage_helper.dart';

class MockStorageHelper extends StorageHelper {
  String? _uri;
  int _parallel = 16;
  String _quality = '1080p';
  String _language = 'jpn';

  @override
  String? getDownloadUri() => _uri;

  @override
  Future<void> setDownloadUri(String uri) async {
    _uri = uri;
  }

  @override
  int getParallelSegments() => _parallel;

  @override
  Future<void> setParallelSegments(int value) async {
    _parallel = value;
  }

  @override
  String getPreferredQuality() => _quality;

  @override
  Future<void> setPreferredQuality(String quality) async {
    _quality = quality;
  }

  @override
  String getPreferredLanguage() => _language;

  @override
  Future<void> setPreferredLanguage(String language) async {
    _language = language;
  }

  @override
  bool hasDownloadUri() => _uri != null;
}

void main() {
  late SettingsRepository repository;
  late MockStorageHelper mockHelper;

  setUp(() {
    mockHelper = MockStorageHelper();
    repository = SettingsRepository(mockHelper);
  });

  group('SettingsRepository', () {
    test('initial state has no folder', () {
      expect(repository.hasDownloadUri(), false);
      expect(repository.getDownloadUri(), isNull);
    });

    test('setDownloadUri updates value', () async {
      await repository.setDownloadUri('/storage/downloads');
      expect(repository.getDownloadUri(), '/storage/downloads');
      expect(repository.hasDownloadUri(), true);
    });

    test('parallel segments defaults to 16', () {
      expect(repository.getParallelSegments(), 16);
    });

    test('setParallelSegments updates value', () async {
      await repository.setParallelSegments(8);
      expect(repository.getParallelSegments(), 8);
    });

    test('quality defaults to 1080p', () {
      expect(repository.getPreferredQuality(), '1080p');
    });

    test('setPreferredQuality updates value', () async {
      await repository.setPreferredQuality('720p');
      expect(repository.getPreferredQuality(), '720p');
    });

    test('language defaults to jpn', () {
      expect(repository.getPreferredLanguage(), 'jpn');
    });

    test('setPreferredLanguage updates value', () async {
      await repository.setPreferredLanguage('eng');
      expect(repository.getPreferredLanguage(), 'eng');
    });
  });
}
