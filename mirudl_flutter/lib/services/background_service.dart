import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import '../data/repositories/download_repository.dart';
import '../data/models/download_entry.dart';
import '../domain/enums/download_status.dart';
import 'hls_downloader_service.dart';
import 'notification_service.dart';

/// Background download service
/// Mirrors DownloadService.java — processes queue in foreground service
class BackgroundService {
  static const String _channelId = 'com.mirudl/downloads';
  static const String _displayName = 'MiruDL Downloads';

  final DownloadRepository _repository;
  final HlsDownloaderService _hlsDownloader;
  final NotificationService _notificationService;
  StreamSubscription<dynamic>? _taskSubscription;
  Timer? _queueCheckTimer;
  bool _isRunning = false;
  bool _initialized = false;
  ServiceInstance? _serviceInstance;

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
        onStart: _onStart,
        autoStart: false,
        onForeground: () {
          _serviceInstance?.invoke('setAsForeground');
        },
        onBackground: () {
          _serviceInstance?.invoke('setAsBackground');
        },
      ),
    );

    // Listen for task updates from the service isolate
    service.on('updateProgress').listen(_handleProgressUpdate);
    service.on('jobComplete').listen(_handleJobComplete);
    service.on('jobFailed').listen(_handleJobFailed);
    service.on('queueEmpty').listen((_) {
      _stopService();
    });

    _initialized = true;
  }

  /// Start processing the download queue
  Future<void> start() async {
    if (_isRunning) return;

    final service = FlutterBackgroundService();
    await service.startService();

    // Send a start signal to the service isolate
    service.invoke('processQueue');
    _isRunning = true;
  }

  /// Stop the background service
  Future<void> stop() async {
    _isRunning = false;
    _queueCheckTimer?.cancel();

    final service = FlutterBackgroundService();
    await service.invoke('stopService');
  }

  /// Check if the service is currently running
  bool get isRunning => _isRunning;

  /// Dispose resources
  void dispose() {
    _queueCheckTimer?.cancel();
    _taskSubscription?.cancel();
  }

  // ─── Internal: Service Isolate Callback ─────────────────────────

  void _onStart(ServiceInstance instance) {
    _serviceInstance = instance;

    // Listen for commands from the main isolate
    instance.on('processQueue').listen((_) {
      _processQueue(instance);
    });

    instance.on('cancelJob').listen((data) {
      if (data is String) {
        final job = _repository.find(data);
        if (job != null) {
          _repository.cancel(job);
        }
      }
    });

    instance.on('stopService').listen((_) {
      instance.stopSelf();
    });

    // Set as foreground service
    instance.setAsForegroundService();
  }

  // ─── Queue Processing ───────────────────────────────────────────

  Future<void> _processQueue(ServiceInstance instance) async {
    if (_repository.isRunning) return;
    _repository.isRunning = true;

    try {
      while (true) {
        // Get snapshot of jobs
        final jobs = _repository.snapshot();

        // Find next unfinished job
        DownloadJob? currentJob;
        for (final job in jobs) {
          if (!job.finished && !job.cancelled) {
            currentJob = job;
            break;
          }
        }

        if (currentJob == null) break; // Queue empty

        // Process this job
        await _processJob(currentJob, instance);
      }
    } finally {
      _repository.isRunning = false;
      instance.invoke('queueEmpty');
    }
  }

  Future<void> _processJob(
    DownloadJob job,
    ServiceInstance instance,
  ) async {
    try {
      // Update status to downloading
      job.status = DownloadStatus.downloading;
      instance.invoke('updateProgress', {
        'id': job.id,
        'percent': 0,
        'status': 'downloading',
      });

      // Get output directory
      final outputDir = await getApplicationDocumentsDirectory();
      final downloadPath = '${outputDir.path}/downloads';

      // Perform the download
      final outputPath = await _hlsDownloader.download(
        playlistUrl: job.hlsUrl,
        fileName: '${job.animeTitle} - ${job.episodeTitle}',
        parallelSegments: AppConstants.defaultParallel,
        outputDirectory: downloadPath,
        onProgress: (percent, downloaded, total) {
          job.percent = percent;
          instance.invoke('updateProgress', {
            'id': job.id,
            'percent': percent,
            'downloaded': downloaded,
            'total': total,
            'status': 'downloading',
          });
        },
        cancelCheck: () => job.cancelled,
      );

      if (job.cancelled) {
        job.status = DownloadStatus.cancelled;
        job.finished = true;
        instance.invoke('jobFailed', {
          'id': job.id,
          'error': 'Cancelled',
        });
        return;
      }

      // Mark as completed
      job.status = DownloadStatus.completed;
      job.finished = true;
      job.outputUri = outputPath;
      job.percent = 100;

      // Save to history
      await _repository.addHistory(DownloadEntry(
        uri: outputPath,
        title: job.episodeTitle.isNotEmpty
            ? job.episodeTitle
            : job.animeTitle,
        parent: job.animeTitle,
        size: await _getFileSize(outputPath),
        completedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      instance.invoke('jobComplete', {
        'id': job.id,
        'title': job.episodeTitle,
        'outputPath': outputPath,
      });
    } catch (e) {
      job.status = DownloadStatus.failed;
      job.finished = true;
      job.error = e.toString();

      instance.invoke('jobFailed', {
        'id': job.id,
        'error': e.toString(),
      });
    }
  }

  // ─── Handlers (in main isolate) ─────────────────────────────────

  void _handleProgressUpdate(dynamic data) {
    if (data is Map) {
      final id = data['id'] as String?;
      final percent = data['percent'] as int?;

      if (id != null && percent != null) {
        final job = _repository.find(id);
        if (job != null) {
          job.percent = percent;
          job.status = DownloadStatus.downloading;
        }

        // Show notification
        final title = data['title'] as String? ?? 'Downloading';
        _notificationService.showProgress(
          id: AppConstants.notificationId,
          title: 'MiruDL',
          message: title,
          progress: percent,
        );
      }
    }
  }

  void _handleJobComplete(dynamic data) {
    if (data is Map) {
      final id = data['id'] as String?;
      final title = data['title'] as String? ?? 'Complete';

      // Show completion notification
      _notificationService.showComplete(
        id: AppConstants.notificationId,
        title: '✅ Download Complete',
        message: title,
      );
    }
  }

  void _handleJobFailed(dynamic data) {
    if (data is Map) {
      final id = data['id'] as String?;
      final error = data['error'] as String? ?? 'Unknown error';

      // Show error notification
      _notificationService.showError(
        id: AppConstants.notificationId,
        title: '❌ Download Failed',
        message: error,
      );
    }
  }

  void _stopService() {
    _isRunning = false;
    _notificationService.cancel(AppConstants.notificationId);
    FlutterBackgroundService().invoke('stopService');
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Future<int> _getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }
}

/// Extension to provide clamp for int
