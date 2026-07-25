import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/models/download_entry.dart';

void main() {
  group('DownloadEntry', () {
    test('constructor sets fields correctly', () {
      final entry = DownloadEntry(
        uri: '/path/to/file.mp4',
        title: 'Episode 1',
        parent: 'Naruto',
        size: 1024 * 1024 * 150,
        completedAt: 1700000000000,
      );

      expect(entry.uri, '/path/to/file.mp4');
      expect(entry.title, 'Episode 1');
      expect(entry.parent, 'Naruto');
      expect(entry.size, 157286400);
      expect(entry.completedAt, 1700000000000);
    });

    test('key returns uri when available', () {
      final entry = DownloadEntry(uri: '/path/to/file.mp4', title: 'Episode');
      expect(entry.key, '/path/to/file.mp4');
    });

    test('key returns title when uri is empty', () {
      final entry = DownloadEntry(uri: '', title: 'Episode 1');
      expect(entry.key, 'Episode 1');
    });

    test('parentName returns parent when available', () {
      final entry = DownloadEntry(uri: '', title: '', parent: 'One Piece');
      expect(entry.parentName, 'One Piece');
    });

    test('parentName returns default when parent is empty', () {
      final entry = DownloadEntry(uri: '', title: '', parent: '');
      expect(entry.parentName, 'AniDB');
    });

    test('fromJson creates model correctly', () {
      final json = {
        'uri': '/path/video.mp4',
        'title': 'Episode 5',
        'parent': 'Attack on Titan',
        'size': 524288000,
        'completed_at': 1700000000000,
      };

      final entry = DownloadEntry.fromJson(json);

      expect(entry.uri, '/path/video.mp4');
      expect(entry.title, 'Episode 5');
      expect(entry.parent, 'Attack on Titan');
      expect(entry.size, 524288000);
      expect(entry.completedAt, 1700000000000);
    });

    test('toJson produces correct map', () {
      final entry = DownloadEntry(
        uri: 'uri',
        title: 'title',
        parent: 'parent',
        size: 100,
        completedAt: 200,
      );

      final json = entry.toJson();

      expect(json['uri'], 'uri');
      expect(json['title'], 'title');
      expect(json['parent'], 'parent');
      expect(json['size'], 100);
      expect(json['completed_at'], 200);
    });

    test('toJson and fromJson are inverses', () {
      final original = DownloadEntry(
        uri: 'test.mp4',
        title: 'Episode 10',
        parent: 'Demon Slayer',
        size: 300 * 1024 * 1024,
        completedAt: 1710000000000,
      );

      final json = original.toJson();
      final reconstructed = DownloadEntry.fromJson(json);

      expect(reconstructed.uri, original.uri);
      expect(reconstructed.title, original.title);
      expect(reconstructed.parent, original.parent);
      expect(reconstructed.size, original.size);
      expect(reconstructed.completedAt, original.completedAt);
    });
  });
}
