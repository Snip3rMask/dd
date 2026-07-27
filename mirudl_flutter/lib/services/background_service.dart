import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:io';
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
  bool _processing = false;

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

    // Listen for events from the background service isolate
    service.on('processQueue').listen((_) => _processQueue());
    service.on('cancelJob').listen((data) {
      final jobId = data?['jobId']?.toString() ?? data?.toString();
      if (jobId != null && jobId.isNotEmpty) {
        final job = _repository.find(jobId);
        if (job != null) _repository.cancel(job);
      }
    });
    service.on('stop').listen((_) {
      _isRunning = false;
    });

    _initialized = true;
  }

  /// Start or signal the download queue processor
  Future<void> start() async {
    // Try to start the foreground service for persistent notification.
    // On some Android versions this may crash at the native level, so
    // we guard it tightly. Even without the service, downloads work.
    if (!_isRunning) {
      try {
        final service = FlutterBackgroundService();
        await service.startService();
        _isRunning = true;
      } catch (e) {
        // Foreground service failed — process without it.
        print('[BackgroundService] startService failed: $e');
        _isRunning = true;
      }
    }

    // Process the queue directly on the main isolate
    _processQueue();
  }

  /// Stop the background service
  Future<void> stop() async {
    _isRunning = false;
    final service = FlutterBackgroundService();
    try {
      service.invoke("stop");
    } catch (_) {}
  }

  void dispose() {
    _isRunning = false;
  }

  // ─── Service Callbacks ──────────────────────────────────────────

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance instance) {
    // CRITICAL: Android requires startForeground() to be called within a
    // few seconds of startForegroundService(), or the OS kills the app with
    // a fatal RemoteServiceException (ForegroundServiceDidNotStartInTimeException
    // on Android 12+, plain RemoteServiceException on Android 8-11). This must
    // happen immediately — before any other work — or the app crashes natively
    // in a way Dart's error handlers (FlutterError.onError, PlatformDispatcher.onError,
    // runZonedGuarded) can never catch, since the crash occurs outside the Dart VM.
    if (instance is AndroidServiceInstance) {
      instance.setAsForegroundService();
    }

    instance.on('stop').listen((_) => instance.stopSelf());
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance instance) async {
    return true;
  }

  // ─── Queue Processing ──────────────────────────────────────────

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

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
      _processing = false;
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

      await _notificationService.showComplete(
        id: AppConstants.notificationId,
        title: '✅ Download Complete',
        message: job.episodeTitle,
      );
    } catch (e) {
      job.status = DownloadStatus.failed;
      job.finished = true;
      job.error = e.toString();

      await _notificationService.showError(
        id: AppConstants.notificationId,
        title: '❌ Download Failed',
        message: e.toString(),
      );
    }
  }

  void _updateNotification(DownloadJob job) {
    // Fire-and-forget progress notification
    unawaited(
      _notificationService.showProgress(
        id: AppConstants.notificationId,
        title: 'MiruDL',
        message: job.episodeTitle,
        progress: job.percent,
      ).catchError((_) {}),
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
