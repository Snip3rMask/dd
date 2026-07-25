import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import "dart:io";
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/download_repository.dart';
import '../data/models/download_entry.dart';
import '../domain/enums/download_status.dart';
import 'hls_downloader_service.dart';
import 'notification_service.dart';

/// Background download service
/// Mirrors DownloadService.java — processes queue in foreground service
class BackgroundService {
  static const String _channelId = 'com.mirudl/downloads';

  final DownloadRepository _repository;
  final HlsDownloaderService _hlsDownloader;
  final NotificationService _notificationService;
  bool _isRunning = false;
  bool _initialized = false;

  BackgroundService({
    required DownloadRepository repository,
    required HlsDownloaderService hlsDownloader,
    required NotificationService notificationService,
  })  : _repository = repository,
        _hlsDownloader = hlsDownloader,
        _notificationService = notificationService;

  /// Initialize the background service
  Future<void> init() async {
    if (_initialized) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'MiruDL',
        initialNotificationContent: 'Download service ready',
        foregroundServiceNotificationId: AppConstants.notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    service.on('processQueue').listen((_) => _processQueue());
    service.on('cancelJob').listen((data) {
      if (data is String) { final jobId = data as String;
        final job = _repository.find(jobId);
        if (job != null) _repository.cancel(job);
      }
    });
    service.on('stop').listen((_) {
      _isRunning = false;
    });

    _initialized = true;
  }

  /// Start processing the download queue
  Future<void> start() async {
    if (_isRunning) return;
    final service = FlutterBackgroundService();
    await service.startService();
    _isRunning = true;
    // Signal the service to start processing
    service.invoke('processQueue');
  }

  /// Stop the background service
  Future<void> stop() async {
    _isRunning = false;
    final service = FlutterBackgroundService();
    service.invoke("stop");
  }
  void dispose() {
    // Nothing to clean up
  }

  // ─── Service Callbacks ──────────────────────────────────────────

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance instance) {
    // Foreground mode set via AndroidConfiguration
    instance.on('stop').listen((_) => instance.stopSelf());
    // The instance stays alive and listens for events
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance instance) async {
    return true;
  }

  // ─── Queue Processing ──────────────────────────────────────────

  Future<void> _processQueue() async {
    if (_repository.isRunning) return;
    _repository.isRunning = true;

    try {
      while (true) {
        final jobs = _repository.snapshot();
        DownloadJob? currentJob;
        for (final job in jobs) {
          if (!job.finished && !job.cancelled) {
            currentJob = job;
            break;
          }
        }
        if (currentJob == null) break;

        await _processJob(currentJob);
      }
    } finally {
      _repository.isRunning = false;
    }
  }

  Future<void> _processJob(DownloadJob job) async {
    try {
      job.status = DownloadStatus.downloading;
      _updateNotification(job);

      final outputDir = (await getApplicationDocumentsDirectory()).path;
      final downloadPath = '$outputDir/downloads';

      final outputPath = await _hlsDownloader.download(
        playlistUrl: job.hlsUrl,
        fileName: '${job.animeTitle} - ${job.episodeTitle}',
        parallelSegments: AppConstants.defaultParallel,
        outputDirectory: downloadPath,
        onProgress: (percent, downloaded, total) {
          job.percent = percent;
          _updateNotification(job);
        },
        cancelCheck: () => job.cancelled,
      );

      if (job.cancelled) {
        job.status = DownloadStatus.cancelled;
        job.finished = true;
        return;
      }

      job.status = DownloadStatus.completed;
      job.finished = true;
      job.outputUri = outputPath;
      job.percent = 100;

      await _repository.addHistory(DownloadEntry(
        uri: outputPath,
        title: job.episodeTitle.isNotEmpty
            ? job.episodeTitle
            : job.animeTitle,
        parent: job.animeTitle,
        size: await _getFileSize(outputPath),
        completedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      _notificationService.showComplete(
        id: AppConstants.notificationId,
        title: '✅ Download Complete',
        message: job.episodeTitle,
      );
    } catch (e) {
      job.status = DownloadStatus.failed;
      job.finished = true;
      job.error = e.toString();

      _notificationService.showError(
        id: AppConstants.notificationId,
        title: '❌ Download Failed',
        message: e.toString(),
      );
    }
  }

  void _updateNotification(DownloadJob job) {
    _notificationService.showProgress(
      id: AppConstants.notificationId,
      title: 'MiruDL',
      message: job.episodeTitle,
      progress: job.percent,
    );
  }

  Future<int> _getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) return await file.length();
    } catch (_) {}
    return 0;
  }
}
