import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/helpers.dart';
import '../core/errors/exceptions.dart';

/// Progress callback: (percent, downloadedSegments, totalSegments)
typedef ProgressCallback = void Function(int percent, int downloaded, int total);

/// Cancel check callback
typedef CancelCheck = bool Function();

/// HLS download and merge service
/// Mirrors HlsDownloader.java with full parallelism and FFmpeg merge
class HlsDownloaderService {
  static const int _maxParallel = 32;
  static const String _userAgent = ApiConstants.userAgent;
  static const String _referer = '${ApiConstants.baseUrl}/';

  // ─── Public API ─────────────────────────────────────────────────

  /// Download an HLS stream and return the output file path
  Future<String> download({
    required String playlistUrl,
    required String fileName,
    required int parallelSegments,
    required String outputDirectory,
    ProgressCallback? onProgress,
    CancelCheck? cancelCheck,
  }) async {
    // 1. Fetch playlist content
    final playlist = await _fetchText(playlistUrl);

    // 2. Check if master playlist → resolve first variant
    String mediaUrl = playlistUrl;
    if (playlist.contains('#EXT-X-STREAM-INF')) {
      final variants = _parseMasterPlaylist(playlist, playlistUrl);
      if (variants.isEmpty) {
        throw HlsException('No variants found in master playlist');
      }
      // Pick the highest quality variant
      variants.sort((a, b) => _qualityScore(b.quality)
          .compareTo(_qualityScore(a.quality)));
      mediaUrl = variants.first.url;
    }

    // 3. Fetch media playlist
    final mediaPlaylist = await _fetchText(mediaUrl);

    // 4. Check encryption
    if (mediaPlaylist.contains('#EXT-X-KEY:')) {
      throw HlsException('Encrypted streams are not supported');
    }

    // 5. Parse segment URLs
    final segments = _parseSegments(mediaPlaylist, mediaUrl);
    if (segments.isEmpty) {
      throw HlsException('No HLS segments found');
    }

    // 6. Get init segment (if present — fMP4)
    final mapUrl = _parseInitSegment(mediaPlaylist, mediaUrl);

    // 7. Create temp directory
    final tempDir = Directory(
      '${(await getTemporaryDirectory()).path}/hls_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    try {
      // 8. Download segments in parallel
      await _downloadSegmentsInParallel(
        segments,
        tempDir,
        parallelSegments.clamp(1, _maxParallel),
        onProgress,
        cancelCheck,
      );

      // 9. Merge segments into MP4
      final cleanName = Helpers.sanitizeFileName(fileName);
      final innerDir = Helpers.extractParentName(fileName);
      final animeDir = Directory('$outputDirectory/$innerDir');
      if (!await animeDir.exists()) {
        await animeDir.create(recursive: true);
      }
      final outputPath = '${animeDir.path}/$cleanName.mp4';

      await _mergeSegments(
        tempDir,
        outputPath,
        mapUrl,
        segments.length,
        cancelCheck,
      );

      return outputPath;
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  // ─── Playlist Parsing ───────────────────────────────────────────

  List<VideoVariant> _parseMasterPlaylist(String content, String baseUrl) {
    final variants = <VideoVariant>[];
    final lines = content.split('\n');
    String? pendingInf;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#EXT-X-STREAM-INF:')) {
        pendingInf = trimmed;
      } else if (pendingInf != null &&
          trimmed.isNotEmpty &&
          !trimmed.startsWith('#')) {
        final quality = _extractRes(pendingInf);
        final url = Helpers.resolveUrl(trimmed, baseUrl);
        variants.add(VideoVariant(quality, url));
        pendingInf = null;
      }
    }
    return variants;
  }

  List<String> _parseSegments(String content, String baseUrl) {
    final segments = <String>[];
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          !trimmed.startsWith('#') &&
          !trimmed.startsWith('"')) {
        segments.add(Helpers.resolveUrl(trimmed, baseUrl));
      }
    }
    return segments;
  }

  String? _parseInitSegment(String content, String baseUrl) {
    final match = RegExp(r'#EXT-X-MAP:URI="([^"]+)"').firstMatch(content);
    if (match != null) {
      return Helpers.resolveUrl(match.group(1)!, baseUrl);
    }
    return null;
  }

  // ─── Download Logic ─────────────────────────────────────────────

  Future<void> _downloadSegmentsInParallel(
    List<String> urls,
    Directory tempDir,
    int parallel,
    ProgressCallback? onProgress,
    CancelCheck? cancelCheck,
  ) async {
    final total = urls.length;
    int finished = 0;
    bool failed = false;
    int started = 0;

    while (started < total && !failed) {
      if (cancelCheck != null && cancelCheck()) {
        throw CancellationException('Download cancelled');
      }

      final batchStart = started;
      final batchEnd = (started + parallel).clamp(0, total);
      started = batchEnd;

      final futures = <Future<int?>>[];
      for (int i = batchStart; i < batchEnd; i++) {
        futures.add(_downloadSingleSegment(i, urls[i], tempDir));
      }

      final results = await Future.wait(futures, eagerError: false);

      for (final result in results) {
        finished++;
        if (result != null) {
          failed = true;
        }
        final percent = ((finished / total) * 100).round();
        onProgress?.call(percent.clamp(0, 100), finished, total);
      }
    }
  }

  Future<int?> _downloadSingleSegment(int index, String url, Directory tempDir) async {
    try {
      final data = await _fetchBytes(url);
      final file = File('${tempDir.path}/seg_$index.ts');
      await file.writeAsBytes(data);
      return null;
    } catch (e) {
      return index;
    }
  }

  // ─── Merge Logic ────────────────────────────────────────────────

  Future<void> _mergeSegments(
    Directory tempDir,
    String outputPath,
    String? mapUrl,
    int totalSegments,
    CancelCheck? cancelCheck,
  ) async {
    try {
      await _mergeWithFfmpeg(tempDir, outputPath, mapUrl, totalSegments, cancelCheck);
      return;
    } catch (e) {
      // Fallback
    }
    await _mergeByConcat(tempDir, outputPath, mapUrl, totalSegments);
  }

  Future<void> _mergeWithFfmpeg(
    Directory tempDir,
    String outputPath,
    String? mapUrl,
    int totalSegments,
    CancelCheck? cancelCheck,
  ) async {
    final fileList = StringBuffer();
    for (int i = 0; i < totalSegments; i++) {
      final segFile = File('${tempDir.path}/seg_$i.ts');
      if (await segFile.exists()) {
        fileList.writeln("file '${segFile.path}'");
      }
    }
    final listFile = File('${tempDir.path}/file_list.txt');
    await listFile.writeAsString(fileList.toString());

    final result = await Process.run(
      'ffmpeg',
      ['-f', 'concat', '-safe', '0', '-i', listFile.path, '-c', 'copy', '-y', outputPath],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw HlsException(
        'FFmpeg merge failed: ${result.stderr.toString().substring(0, 200)}',
      );
    }
  }

  Future<void> _mergeByConcat(
    Directory tempDir,
    String outputPath,
    String? mapUrl,
    int totalSegments,
  ) async {
    final outFile = File(outputPath);
    final ios = await outFile.open(mode: FileMode.write);

    try {
      if (mapUrl != null) {
        final initData = await _fetchBytes(mapUrl);
        ios.writeFromSync(initData);
      }
      for (int i = 0; i < totalSegments; i++) {
        final segFile = File('${tempDir.path}/seg_$i.ts');
        if (await segFile.exists()) {
          final data = await segFile.readAsBytes();
          ios.writeFromSync(data);
        }
      }
    } finally {
      await ios.close();
    }
  }

  // ─── HTTP Helpers ───────────────────────────────────────────────

  Future<String> _fetchText(String url) async {
    final client = HttpClient();
    client.userAgent = _userAgent;
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Referer', _referer);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HlsException('HTTP ${response.statusCode} for $url');
      }
      final text = await response.transform(utf8.decoder).join();
      return text;
    } catch (e) {
      if (e is HlsException) rethrow;
      throw HlsException('Failed to fetch $url: $e');
    } finally {
      client.close();
    }
  }

  Future<List<int>> _fetchBytes(String url) async {
    final client = HttpClient();
    client.userAgent = _userAgent;
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Referer', _referer);
      final response = await request.close();
      if (response.statusCode != 200) return [];
      // Collect chunks into a list to avoid O(n²) copying
      final chunks = <List<int>>[];
      int totalLength = 0;
      await for (final chunk in response) {
        chunks.add(chunk);
        totalLength += chunk.length;
      }
      final result = List<int>.filled(totalLength, 0);
      int offset = 0;
      for (final chunk in chunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      return result;
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────

  int _qualityScore(String quality) {
    if (quality.contains('x')) {
      final parts = quality.split('x');
      return int.tryParse(parts.last) ?? 0;
    }
    return int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  String _extractRes(String infLine) {
    final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(infLine);
    if (resMatch != null) return resMatch.group(1)!;
    final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(infLine);
    if (bwMatch != null) return '${bwMatch.group(1)}bps';
    return 'Auto';
  }
}

/// HLS variant stream info
class VideoVariant {
  final String quality;
  final String url;
  VideoVariant(this.quality, this.url);
}
