import 'package:flutter/foundation.dart';

import '../../data/models/anime_item.dart';
import '../../data/models/episode_item.dart';
import '../../data/models/video_source.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/usecases/download_episode.dart';
import '../../domain/usecases/get_episodes.dart';
import '../../domain/usecases/get_languages.dart';
import '../../domain/usecases/get_qualities.dart';
import '../../domain/usecases/resolve_hls.dart';
import '../../services/background_service.dart';
import '../../core/utils/logger.dart';

/// ViewModel for the Anime Detail / Episode screen
class DetailProvider extends ChangeNotifier {
  final GetEpisodes _getEpisodes;
  final GetLanguages _getLanguages;
  final ResolveHls _resolveHls;
  final GetQualities _getQualities;
  final DownloadEpisode _downloadEpisode;
  final SettingsRepository _settings;
  final BackgroundService _backgroundService;

  AnimeItem? _anime;
  List<EpisodeItem> _episodes = [];
  bool _isLoading = false;
  String? _error;
  String _animeTitle = '';

  DetailProvider(
    this._getEpisodes,
    this._getLanguages,
    this._resolveHls,
    this._getQualities,
    this._downloadEpisode,
    this._settings,
    this._backgroundService,
  );

  AnimeItem? get anime => _anime;
  List<EpisodeItem> get episodes => _episodes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get animeTitle => _animeTitle;

  /// Initialize with anime info
  void setAnime(AnimeItem anime) {
    _anime = anime;
    _animeTitle = anime.title;
  }

  /// Load episodes for the anime
  Future<void> loadEpisodes(String animeId) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _episodes = await _getEpisodes.call(animeId);
    } catch (e) {
      _error = e.toString();
      _episodes = [];
    }

    _isLoading = false;
    _safeNotify();
  }

  /// Resolve HLS URL and start download for an episode
  Future<void> resolveAndDownload(EpisodeItem episode) async {
    try {
      // If no HLS URL, resolve from embed
      if (episode.hlsUrl.isEmpty) {
        final languages = await _getLanguages.call(episode.id);
        if (languages.isEmpty) return;

        final preferredLang = _settings.getPreferredLanguage();
        VideoSource? selected;
        for (final lang in languages) {
          if (lang.language == preferredLang) {
            selected = lang;
            break;
          }
        }
        selected ??= languages.first;

        final hlsUrl = await _resolveHls.call(selected.url);
        if (hlsUrl == null) return;

        episode = EpisodeItem(
          id: episode.id,
          number: episode.number,
          number2: episode.number2,
          filler: episode.filler,
          title: episode.title,
          embedUrl: selected.url,
          hlsUrl: hlsUrl,
          language: selected.language,
          langName: selected.quality,
        );
      }

      // Get quality variants and select preferred
      String downloadUrl = episode.hlsUrl;
      try {
        final variants = await _getQualities.call(episode.hlsUrl);
        final preferredQuality = _settings.getPreferredQuality();
        for (final v in variants) {
          if (v.quality.contains(preferredQuality.replaceAll('p', ''))) {
            downloadUrl = v.url;
            break;
          }
        }
      } catch (_) {
        // Use default URL if quality fetch fails
      }

      // Enqueue download
      await _downloadEpisode.call(
        animeTitle: _animeTitle,
        episodeTitle: 'Episode ${episode.label}',
        quality: _settings.getPreferredQuality(),
        language: episode.language.isNotEmpty ? episode.language : 'jpn',
        hlsUrl: downloadUrl,
      );

      // Start background processing of the queue
      await _backgroundService.start();

      _safeNotify();
    } catch (e, stack) {
      await Logger.instance.logException(e, stack, screen: 'DetailProvider.resolveAndDownload');
      _error = e.toString();
      _safeNotify();
    }
  }

  /// Download all episodes in sequence
  Future<void> downloadAll() async {
    if (_episodes.isEmpty) return;

    for (final ep in _episodes) {
      await resolveAndDownload(ep);
    }
  }

  /// Safe notifyListeners that won't throw if disposed
  void _safeNotify() {
    try {
      notifyListeners();
    } catch (_) {
      // Widget already disposed — ignore
    }
  }
}
