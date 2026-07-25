import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/models/episode_item.dart';

void main() {
  group('EpisodeItem', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1,
        'number': 1,
        'number2': 0,
        'filler': false,
        'title': 'The Beginning',
        'embed_url': 'https://anidb.app/embed/123',
        'hls_url': 'https://example.com/master.m3u8',
        'language': 'jpn',
        'lang_name': 'Sub (Japanese)',
      };

      final item = EpisodeItem.fromJson(json);

      expect(item.id, 1);
      expect(item.number, 1);
      expect(item.number2, 0);
      expect(item.filler, false);
      expect(item.title, 'The Beginning');
      expect(item.embedUrl, 'https://anidb.app/embed/123');
      expect(item.hlsUrl, 'https://example.com/master.m3u8');
      expect(item.language, 'jpn');
      expect(item.langName, 'Sub (Japanese)');
    });

    test('label returns single number', () {
      final item = EpisodeItem(id: 1, number: 5);
      expect(item.label, '5');
    });

    test('label returns range when number2 differs', () {
      final item = EpisodeItem(id: 1, number: 5, number2: 6);
      expect(item.label, '5-6');
    });

    test('label returns single number when number2 equals number', () {
      final item = EpisodeItem(id: 1, number: 5, number2: 5);
      expect(item.label, '5');
    });

    test('toJson produces correct map', () {
      final item = EpisodeItem(
        id: 10,
        number: 3,
        number2: 0,
        filler: true,
        title: 'Filler Episode',
        embedUrl: 'https://embed.url',
        hlsUrl: 'https://hls.url',
        language: 'eng',
        langName: 'Dub (English)',
      );

      final json = item.toJson();

      expect(json['id'], 10);
      expect(json['number'], 3);
      expect(json['filler'], true);
      expect(json['language'], 'eng');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final item = EpisodeItem.fromJson(json);

      expect(item.id, 0);
      expect(item.number, 0);
      expect(item.filler, false);
      expect(item.title, '');
    });
  });
}
