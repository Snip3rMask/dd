import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/helpers.dart';
import '../../models/anime_item.dart';
import '../../models/episode_item.dart';
import '../../models/video_source.dart';

/// REST API client for anidb.app
/// Mirrors the functionality from AniDbApi.java
class AniDbApi {
  final ApiClient _client;
  final Dio get dio => _client.dio;

  AniDbApi(this._client);

  /// Search anime by query string
  Future<List<AnimeItem>> search(String query) async {
    try {
      final response = await dio.get(
        '${ApiConstants.searchEndpoint}?q=${Uri.encodeComponent(query)}',
        options: _client.htmlOptions,
      );
      return _parseSearchResults(response.data as String);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Search failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Parse HTML search results (same logic as Java parseSearchResults)
  List<AnimeItem> _parseSearchResults(String html) {
    final results = <AnimeItem>[];
    final anchorRegex = RegExp(r'<a\s[^>]*data-search-item[^>]*>.*?</a>',
        dotAll: true);

    for (final match in anchorRegex.allMatches(html)) {
      final block = match.group(0)!;

      // Extract href
      final hrefMatch = RegExp(r'href="([^"]+)"').firstMatch(block);
      final url = hrefMatch?.group(1) ?? '';
      final parts = url.split('-');
      final id = parts.isNotEmpty ? parts.last : '';

      if (id.isEmpty) continue;

      // Extract title
      final titleMatch = RegExp(r'line-clamp-1">(.*?)</p>', dotAll: true)
          .firstMatch(block);
      final title = titleMatch != null
          ? _stripHtml(titleMatch.group(1)!.trim())
          : 'Unknown';

      // Extract thumbnail
      final imgMatch =
          RegExp(r'src="([^"]+)"').firstMatch(block);
      final thumb = imgMatch?.group(1) ?? '';

      results.add(AnimeItem(
        id: id,
        title: title,
        thumbnail: thumb,
        url: url,
      ));
    }
    return results;
  }

  /// Get episodes for an anime
  Future<List<EpisodeItem>> getEpisodes(String animeId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.animeApiEndpoint}/$animeId/episodes',
        options: _client.jsonOptions,
      );
      final data = response.data as Map<String, dynamic>;
      final episodesJson = data['episodes'] as List<dynamic>;
      return episodesJson
          .map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get episodes',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get available languages/embed URLs for an episode
  Future<List<VideoSource>> getEpisodeLanguages(int episodeId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.episodeApiEndpoint}/$episodeId/languages',
        options: _client.jsonOptions,
      );
      final data = response.data as Map<String, dynamic>;
      final languagesJson = data['languages'] as List<dynamic>;
      return languagesJson
          .map((l) => VideoSource(
                quality: l['name']?.toString() ?? 'Source',
                url: l['embed_url']?.toString() ?? '',
                language: l['code']?.toString() ?? 'jpn',
                server: 'AniDB',
              ))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get languages',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Resolve HLS URL from an embed page
  Future<String?> resolveHlsFromEmbed(String embedUrl) async {
    try {
      final response = await dio.get(
        embedUrl,
        options: Options(
          headers: Map<String, dynamic>.from(ApiConstants.htmlHeaders),
        ),
      );
      final html = response.data as String;

      // Look for JW Player file configuration
      final fileRegexes = [
        RegExp(r'file:\s*"([^"]+)"'),
        RegExp(r"file:\s*'([^']+)'"),
        RegExp(r'file:\s*`([^`]+)`'),
      ];

      for (final regex in fileRegexes) {
        final match = regex.firstMatch(html);
        if (match != null) {
          return match.group(1);
        }
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Get available quality variants from a master playlist
  Future<List<VideoSource>> getQualities(String masterUrl) async {
    try {
      final response = await dio.get(masterUrl, options: _client.htmlOptions);
      final playlist = response.data as String;
      final variants = <VideoSource>[];
      String? pendingLine;

      for (final raw in playlist.split('\n')) {
        final line = raw.trim();
        if (line.startsWith('#EXT-X-STREAM-INF')) {
          pendingLine = line;
        } else if (pendingLine != null &&
            line.isNotEmpty &&
            !line.startsWith('#')) {
          final quality = Helpers.extractResolution(pendingLine);
          final url = Helpers.resolveUrl(line, masterUrl);
          variants.add(VideoSource(quality: quality, url: url));
          pendingLine = null;
        }
      }

      if (variants.isEmpty) {
        variants.add(VideoSource(quality: 'Auto', url: masterUrl));
      }
      return variants;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get qualities',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get anime title from HTML page
  Future<String?> getAnimeTitle(String animeId) async {
    try {
      final response = await dio.get(
        '/anime/$animeId',
        options: _client.htmlOptions,
      );
      final html = response.data as String;
      final match = RegExp(
        r'property="og:title"\s+content="([^"]+)"',
      ).firstMatch(html);
      return match?.group(1);
    } on DioException {
      return null;
    }
  }

  /// Strip HTML tags from a string
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
