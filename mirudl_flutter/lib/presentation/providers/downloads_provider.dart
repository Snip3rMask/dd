import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/models/download_entry.dart';
import '../../data/repositories/download_repository.dart';

/// ViewModel for the Downloads screen
class DownloadsProvider extends ChangeNotifier {
  final DownloadRepository _repository;

  List<DownloadJob> _activeJobs = [];
  List<DownloadEntry> _completed = [];
  Timer? _refreshTimer;
  bool _disposed = false;

  DownloadsProvider(this._repository) {
    refresh();
  }

  List<DownloadJob> get activeJobs =>
      _activeJobs.where((j) => !j.finished).toList();
  List<DownloadEntry> get completed => _completed;
  bool get hasActive => activeJobs.isNotEmpty;
  bool get hasCompleted => _completed.isNotEmpty;

  /// Refresh both active and completed lists
  void refresh() {
    _activeJobs = _repository.snapshot();
    _completed = _repository.getHistory();
    _safeNotify();
  }

  /// Cancel a download job
  void cancelJob(String jobId) {
    final job = _repository.find(jobId);
    if (job != null) {
      _repository.cancel(job);
      refresh();
    }
  }

  /// Clear all finished download history
  void clearHistory() {
    _repository.clearHistory(_completed);
    _repository.removeFinished();
    refresh();
  }

  /// Remove a single history entry
  void removeEntry(DownloadEntry entry) {
    _repository.removeHistory(entry);
    refresh();
  }

  /// Start auto-refresh timer (call from onResume)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_disposed) refresh();
    });
  }

  /// Stop auto-refresh timer (call from onPause)
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _safeNotify() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    stopAutoRefresh();
    super.dispose();
  }
}
