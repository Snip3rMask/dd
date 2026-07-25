import 'package:flutter_test/flutter_test.dart';
import "package:mirudl_flutter/core/network/api_client.dart";
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';
import 'package:mirudl_flutter/data/models/anime_item.dart';
import 'package:mirudl_flutter/data/models/episode_item.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';
import 'package:mirudl_flutter/core/errors/exceptions.dart';
import 'package:mirudl_flutter/core/errors/failures.dart';

// Manual mock for AniDbApi
class MockAniDbApi extends AniDbApi {
  MockAniDbApi() : super(ApiClient()); // We override all methods

  @override
  Future<List<AnimeItem>> search(String query) async {
    if (query == 'error') throw ServerException('API Error', statusCode: 500);
    if (query == 'naruto') {
      return [
        AnimeItem(id: '1', title: 'Naruto'),
        AnimeItem(id: '2', title: 'One Piece'),
      ];
    }
    return [];
  }

  @override
  Future<List<EpisodeItem>> getEpisodes(String animeId) async {
    if (animeId == '42') {
      return [
        EpisodeItem(id: 1, number: 1),
        EpisodeItem(id: 2, number: 2),
      ];
    }
    throw ServerException('Not found', statusCode: 404);
  }

  @override
  Future<List<VideoSource>> getEpisodeLanguages(int episodeId) async {
    return [
      VideoSource(quality: 'Sub', url: 'url1', language: 'jpn', server: 'AniDB'),
    ];
  }

  @override
  Future<String?> resolveHlsFromEmbed(String embedUrl) async {
    if (embedUrl == 'https://embed.url') {
      return 'https://hls.url/master.m3u8';
    }
    return null;
  }

  @override
  Future<List<VideoSource>> getQualities(String masterUrl) async {
    return [
      VideoSource(quality: '1080p', url: '1080.m3u8'),
      VideoSource(quality: '720p', url: '720.m3u8'),
    ];
  }

  @override
  Future<String?> getAnimeTitle(String animeId) async {
    if (animeId == '42') return 'Naruto';
    throw ServerException('Error');
  }
}

void main() {
  late AnimeRepository repository;

  setUp(() {
    repository = AnimeRepository(MockAniDbApi());
  });

  group('AnimeRepository.searchAnime', () {
    test('returns anime list on success', () async {
      final result = await repository.searchAnime('naruto');
      expect(result, hasLength(2));
      expect(result.first.title, 'Naruto');
    });

    test('throws ServerFailure on ServerException', () async {
      expect(
        () => repository.searchAnime('error'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('AnimeRepository.getEpisodes', () {
    test('returns episode list on success', () async {
      final result = await repository.getEpisodes('42');
      expect(result, hasLength(2));
      expect(result.first.number, 1);
    });

    test('throws ServerFailure on error', () async {
      expect(
        () => repository.getEpisodes('99'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('AnimeRepository.getEpisodeLanguages', () {
    test('returns language list on success', () async {
      final result = await repository.getEpisodeLanguages(1);
      expect(result, hasLength(1));
      expect(result.first.language, 'jpn');
    });
  });

  group('AnimeRepository.resolveHlsFromEmbed', () {
    test('returns HLS URL on success', () async {
      final result = await repository.resolveHlsFromEmbed('https://embed.url');
      expect(result, 'https://hls.url/master.m3u8');
    });

    test('returns null on failure', () async {
      final result = await repository.resolveHlsFromEmbed('bad.url');
      expect(result, isNull);
    });
  });

  group('AnimeRepository.getQualities', () {
    test('returns quality variants on success', () async {
      final result = await repository.getQualities('master.m3u8');
      expect(result, hasLength(2));
      expect(result.first.quality, '1080p');
    });
  });

  group('AnimeRepository.getAnimeTitle', () {
    test('returns title on success', () async {
      final result = await repository.getAnimeTitle('42');
      expect(result, 'Naruto');
    });

    test('returns null on exception', () async {
      final result = await repository.getAnimeTitle('99');
      expect(result, isNull);
    });
  });
}
