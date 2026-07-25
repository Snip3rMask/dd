import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';

void main() {
  group('VideoSource', () {
    test('constructor with two params sets defaults', () {
      final vs = VideoSource(quality: '1080p', url: 'https://example.com/1080.m3u8');

      expect(vs.quality, '1080p');
      expect(vs.url, 'https://example.com/1080.m3u8');
      expect(vs.language, 'jpn');
      expect(vs.server, 'AniDB');
      expect(vs.source, 'primary');
    });

    test('constructor with four params sets all values', () {
      final vs = VideoSource(
        quality: '720p',
        url: 'https://example.com/720.m3u8',
        language: 'eng',
        server: 'AniDB',
      );

      expect(vs.quality, '720p');
      expect(vs.language, 'eng');
      expect(vs.server, 'AniDB');
    });

    test('fromJson creates model correctly', () {
      final json = {
        'quality': '1080p',
        'url': 'https://example.com/video.m3u8',
        'language': 'jpn',
        'server': 'AniDB',
        'source': 'primary',
        'subtitle_url': 'https://example.com/subs.vtt',
      };

      final vs = VideoSource.fromJson(json);

      expect(vs.quality, '1080p');
      expect(vs.url, 'https://example.com/video.m3u8');
      expect(vs.language, 'jpn');
      expect(vs.server, 'AniDB');
      expect(vs.subtitleUrl, 'https://example.com/subs.vtt');
    });

    test('toJson produces correct map', () {
      final vs = VideoSource(
        quality: 'Auto',
        url: 'https://auto.url',
        language: 'eng',
        server: 'AniDB',
      );

      final json = vs.toJson();

      expect(json['quality'], 'Auto');
      expect(json['url'], 'https://auto.url');
      expect(json['language'], 'eng');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final vs = VideoSource.fromJson(json);

      expect(vs.quality, 'Auto');
      expect(vs.url, '');
      expect(vs.language, 'jpn');
      expect(vs.server, 'AniDB');
    });
  });
}
