import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/models/anime_item.dart';

void main() {
  group('AnimeItem', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': '12345',
        'title': 'Test Anime',
        'thumbnail': 'https://example.com/thumb.jpg',
        'rating': '8.5',
        'url': '/anime/test-anime-12345',
        'type': 'TV',
        'year': '2024',
        'status': 'Ongoing',
        'episodes': 24,
      };

      final item = AnimeItem.fromJson(json);

      expect(item.id, '12345');
      expect(item.title, 'Test Anime');
      expect(item.thumbnail, 'https://example.com/thumb.jpg');
      expect(item.rating, '8.5');
      expect(item.url, '/anime/test-anime-12345');
      expect(item.type, 'TV');
      expect(item.year, '2024');
      expect(item.status, 'Ongoing');
      expect(item.episodes, 24);
    });

    test('fromJson handles empty values gracefully', () {
      final json = <String, dynamic>{};
      final item = AnimeItem.fromJson(json);

      expect(item.id, '');
      expect(item.title, 'Unknown');
      expect(item.thumbnail, '');
      expect(item.rating, '');
      expect(item.episodes, 0);
    });

    test('fromJson handles null values gracefully', () {
      final json = {
        'id': null,
        'title': null,
        'thumbnail': null,
        'rating': null,
        'url': null,
        'episodes': null,
      };

      final item = AnimeItem.fromJson(json);

      expect(item.id, '');
      expect(item.title, 'Unknown');
      expect(item.thumbnail, '');
      expect(item.episodes, 0);
    });

    test('toJson produces correct map', () {
      final item = AnimeItem(
        id: '123',
        title: 'Naruto',
        thumbnail: 'thumb.jpg',
        rating: '9.0',
        url: '/naruto',
        type: 'TV',
        year: '2002',
        status: 'Completed',
        episodes: 220,
      );

      final json = item.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'Naruto');
      expect(json['thumbnail'], 'thumb.jpg');
      expect(json['rating'], '9.0');
      expect(json['episodes'], 220);
    });

    test('toJson and fromJson are inverses', () {
      final original = AnimeItem(
        id: '42',
        title: 'Fullmetal Alchemist',
        thumbnail: 'fma.jpg',
        rating: '9.5',
        url: '/fma',
        type: 'TV',
        year: '2003',
        status: 'Completed',
        episodes: 51,
      );

      final json = original.toJson();
      final reconstructed = AnimeItem.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.thumbnail, original.thumbnail);
      expect(reconstructed.episodes, original.episodes);
    });
  });
}
