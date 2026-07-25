import '../datasources/local/download_store.dart';
import '../models/download_entry.dart';
import '../../domain/enums/download_status.dart';

/// Represents a download job in the queue
class DownloadJob {
  final String id;
  final String animeTitle;
  String episodeTitle;
  final String quality;
  final String language;
  final String hlsUrl;
  int percent;
  DownloadStatus status;
  bool cancelled;
  bool finished;
  String? error;
  String? outputUri;

  DownloadJob({
    required this.id,
    required this.animeTitle,
    required this.episodeTitle,
    required this.quality,
    required this.language,
    required this.hlsUrl,
    this.percent = 0,
    this.status = DownloadStatus.queued,
    this.cancelled = false,
    this.finished = false,
    this.error,
    this.outputUri,
  });
}

/// Repository for download queue and history
class DownloadRepository {
  final DownloadStore _store;
  final List<DownloadJob> _jobs = [];
  bool _running = false;

  DownloadRepository(this._store);

  // --- Queue Management ---

  DownloadJob enqueue({
    required String animeTitle,
    required String episodeTitle,
    required String quality,
    required String language,
    required String hlsUrl,
  }) {
    final job = DownloadJob(
      id: _generateId(),
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      quality: quality,
      language: language,
      hlsUrl: hlsUrl,
    );
    _jobs.add(job);
    return job;
  }

  void enqueueAll(List<DownloadJob> jobs) {
    _jobs.addAll(jobs);
  }

  DownloadJob? find(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  void cancel(DownloadJob job) {
    job.cancelled = true;
    job.status = DownloadStatus.cancelled;
    job.finished = true;
  }

  void remove(DownloadJob job) {
    _jobs.remove(job);
  }

  void removeFinished() {
    _jobs.removeWhere((j) => j.finished);
  }

  List<DownloadJob> snapshot() => List.unmodifiable(_jobs);

  int get activeCount => _jobs.where((j) => !j.finished).length;
  bool get isRunning => _running;
  set isRunning(bool value) => _running = value;

  // --- History ---

  List<DownloadEntry> getHistory() => _store.all();
  Future<void> addHistory(DownloadEntry entry) => _store.add(entry);
  Future<void> removeHistory(DownloadEntry entry) => _store.remove(entry);
  Future<void> clearHistory(List<DownloadEntry> entries) =>
      _store.removeAll(entries);

  /// Generate a unique job ID
  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
