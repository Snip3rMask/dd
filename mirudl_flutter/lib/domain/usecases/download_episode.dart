import '../../data/repositories/download_repository.dart';
import '../../data/models/download_entry.dart';

class DownloadEpisode {
  final DownloadRepository _repository;
  DownloadEpisode(this._repository);

  /// Enqueue a download job
  Future<void> call({
    required String animeTitle,
    required String episodeTitle,
    required String quality,
    required String language,
    required String hlsUrl,
  }) async {
    _repository.enqueue(
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      quality: quality,
      language: language,
      hlsUrl: hlsUrl,
    );
  }

  /// Record a completed download in history
  Future<void> recordCompletion({
    required String uri,
    required String title,
    required String parent,
    required int size,
  }) async {
    await _repository.addHistory(DownloadEntry(
      uri: uri,
      title: title,
      parent: parent,
      size: size,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
