import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/anidb_api.dart';
import '../models/anime_item.dart';
import '../models/episode_item.dart';
import '../models/video_source.dart';

/// Repository for anime-related data operations
class AnimeRepository {
  final AniDbApi _api;

  AnimeRepository(this._api);

  Future<List<AnimeItem>> searchAnime(String query) async {
    try {
      return await _api.search(query);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<List<EpisodeItem>> getEpisodes(String animeId) async {
    try {
      return await _api.getEpisodes(animeId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<List<VideoSource>> getEpisodeLanguages(int episodeId) async {
    try {
      return await _api.getEpisodeLanguages(episodeId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<String?> resolveHlsFromEmbed(String embedUrl) async {
    try {
      return await _api.resolveHlsFromEmbed(embedUrl);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  Future<List<VideoSource>> getQualities(String masterUrl) async {
    try {
      return await _api.getQualities(masterUrl);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  Future<String?> getAnimeTitle(String animeId) async {
    try {
      return await _api.getAnimeTitle(animeId);
    } on ServerException {
      return null;
    }
  }
}
