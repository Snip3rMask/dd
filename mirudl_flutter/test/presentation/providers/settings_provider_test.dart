import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/presentation/providers/settings_provider.dart';
import 'package:mirudl_flutter/data/repositories/settings_repository.dart';
import 'package:mirudl_flutter/data/datasources/local/storage_helper.dart';

class MockHelper extends StorageHelper {
  String? _uri;
  int _parallel = 16;
  String _quality = '1080p';
  String _language = 'jpn';

  @override
  String? getDownloadUri() => _uri;
  @override
  Future<void> setDownloadUri(String uri) async => _uri = uri;
  @override
  int getParallelSegments() => _parallel;
  @override
  Future<void> setParallelSegments(int value) async => _parallel = value;
  @override
  String getPreferredQuality() => _quality;
  @override
  Future<void> setPreferredQuality(String quality) async => _quality = quality;
  @override
  String getPreferredLanguage() => _language;
  @override
  Future<void> setPreferredLanguage(String language) async => _language = language;
  @override
  bool hasDownloadUri() => _uri != null;
}

void main() {
  late SettingsProvider provider;

  setUp(() {
    provider = SettingsProvider(SettingsRepository(MockHelper()));
  });

  test('initial state has defaults', () {
    expect(provider.folderPath, isNull);
    expect(provider.parallel, 16);
    expect(provider.quality, '1080p');
    expect(provider.language, 'jpn');
    expect(provider.hasFolder, false);
    expect(provider.languageLabel, 'Sub (Japanese)');
  });

  test('setFolderPath updates value', () async {
    await provider.setFolderPath('/storage/downloads');
    expect(provider.folderPath, '/storage/downloads');
    expect(provider.hasFolder, true);
  });

  test('setParallel updates value', () async {
    await provider.setParallel(8);
    expect(provider.parallel, 8);
  });

  test('setQuality updates value', () async {
    await provider.setQuality('720p');
    expect(provider.quality, '720p');
  });

  test('setLanguage updates value and label', () async {
    await provider.setLanguage('eng');
    expect(provider.language, 'eng');
    expect(provider.languageLabel, 'Dub (English)');
  });
}
