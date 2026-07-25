import 'package:flutter_test/flutter_test.dart';

/// Sample master playlist
const _sampleMaster = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080,CODECS="avc1.640028"
1080.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720,CODECS="avc1.4d401f"
720.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1000000,RESOLUTION=854x480,CODECS="avc1.4d401e"
480.m3u8
''';

/// Sample media playlist
const _sampleMedia = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:10.000,
seg0.ts
#EXTINF:10.000,
seg1.ts
#EXTINF:10.000,
seg2.ts
#EXTINF:10.000,
seg3.ts
#EXT-X-ENDLIST
''';

/// Sample encrypted playlist
const _sampleEncrypted = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-KEY:METHOD=AES-128,URI="https://key.url"
#EXTINF:10.000,
seg0.ts
#EXT-X-ENDLIST
''';

/// Sample with EXT-X-MAP (fMP4)
const _sampleFmp4 = '''
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-MAP:URI="init.mp4"
#EXTINF:10.000,
seg0.m4s
#EXTINF:10.000,
seg1.m4s
#EXT-X-ENDLIST
''';

/// Sample with mixed URL types
const _sampleMixedUrls = '''
#EXTM3U
#EXTINF:10.000,
/absolute/path/seg0.ts
#EXTINF:10.000,
https://cdn.example.com/seg1.ts
#EXTINF:10.000,
relative/seg2.ts
#EXT-X-ENDLIST
''';

void main() {
  group('HLS Parser - Master Playlist', () {
    test('parses master playlist correctly', () {
      final lines = _sampleMaster.split('\n');
      final variants = <Map<String, String>>[];
      String? pendingInf;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXT-X-STREAM-INF:')) {
          pendingInf = trimmed;
        } else if (pendingInf != null && trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          variants.add({'quality': _extractRes(pendingInf), 'url': trimmed});
          pendingInf = null;
        }
      }

      expect(variants, hasLength(3));
      expect(variants[0]['quality'], '1920x1080');
      expect(variants[1]['quality'], '1280x720');
      expect(variants[2]['quality'], '854x480');
      expect(variants[0]['url'], '1080.m3u8');
    });

    test('handles single variant', () {
      final playlist = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1280x720
single.m3u8
''';

      final variants = <Map<String, String>>[];
      String? pendingInf;
      for (final line in playlist.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXT-X-STREAM-INF:')) {
          pendingInf = trimmed;
        } else if (pendingInf != null && trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          variants.add({'quality': _extractRes(pendingInf), 'url': trimmed});
          pendingInf = null;
        }
      }

      expect(variants, hasLength(1));
      expect(variants[0]['quality'], '1280x720');
    });
  });

  group('HLS Parser - Segment Extraction', () {
    test('extracts segments from media playlist', () {
      final segments = <String>[];
      for (final line in _sampleMedia.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#') && !trimmed.startsWith('"')) {
          segments.add(trimmed);
        }
      }

      expect(segments, hasLength(4));
      expect(segments[0], 'seg0.ts');
      expect(segments[3], 'seg3.ts');
    });

    test('returns empty for playlist with only headers', () {
      final playlist = '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-ENDLIST\n';
      final segments = <String>[];
      for (final line in playlist.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#') && !trimmed.startsWith('"')) {
          segments.add(trimmed);
        }
      }
      expect(segments, isEmpty);
    });
  });

  group('HLS Parser - Encryption Detection', () {
    test('detects encrypted streams', () {
      expect(_sampleEncrypted.contains('#EXT-X-KEY:'), true);
    });

    test('detects non-encrypted streams', () {
      expect(_sampleMedia.contains('#EXT-X-KEY:'), false);
    });
  });

  group('HLS Parser - EXT-X-MAP Detection', () {
    test('detects init segment URL', () {
      final match = RegExp(r'#EXT-X-MAP:URI="([^"]+)"').firstMatch(_sampleFmp4);
      expect(match, isNotNull);
      expect(match!.group(1), 'init.mp4');
    });

    test('no init segment in regular playlist', () {
      final match = RegExp(r'#EXT-X-MAP:URI="([^"]+)"').firstMatch(_sampleMedia);
      expect(match, isNull);
    });
  });

  group('HLS Parser - URL Resolution', () {
    String resolveUrl(String value, String base) {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
      if (value.startsWith('/')) {
        final slash = base.indexOf('/', 8);
        return '${slash > 0 ? base.substring(0, slash) : base}$value';
      }
      final slash = base.lastIndexOf('/');
      return '${slash > 0 ? base.substring(0, slash + 1) : base}$value';
    }

    test('resolves relative URL', () {
      final result = resolveUrl('seg0.ts', 'https://cdn.example.com/hls/play.m3u8');
      expect(result, 'https://cdn.example.com/hls/seg0.ts');
    });

    test('resolves absolute path', () {
      final result = resolveUrl('/hls/seg0.ts', 'https://cdn.example.com/hls/play.m3u8');
      expect(result, 'https://cdn.example.com/hls/seg0.ts');
    });

    test('preserves absolute URL', () {
      final result = resolveUrl('https://other.com/seg.ts', 'https://cdn.example.com/play.m3u8');
      expect(result, 'https://other.com/seg.ts');
    });

    test('resolves mixed URLs from playlist', () {
      final base = 'https://cdn.example.com/hls/playlist.m3u8';
      final segments = <String>[];

      for (final line in _sampleMixedUrls.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#') && !trimmed.startsWith('"')) {
          segments.add(resolveUrl(trimmed, base));
        }
      }

      expect(segments, hasLength(3));
      expect(segments[0], 'https://cdn.example.com/absolute/path/seg0.ts');
      expect(segments[1], 'https://cdn.example.com/seg1.ts');
      expect(segments[2], 'https://cdn.example.com/hls/relative/seg2.ts');
    });
  });

  group('HLS Parser - Quality Score Sorting', () {
    int qualityScore(String quality) {
      if (quality.contains('x')) {
        final parts = quality.split('x');
        return int.tryParse(parts.last) ?? 0;
      }
      return int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    test('higher resolution has higher score', () {
      expect(qualityScore('1920x1080'), greaterThan(qualityScore('1280x720')));
      expect(qualityScore('3840x2160'), greaterThan(qualityScore('1920x1080')));
    });

    test('sorts variants by quality descending', () {
      final variants = ['854x480', '1920x1080', '1280x720'];
      variants.sort((a, b) => qualityScore(b).compareTo(qualityScore(a)));

      expect(variants[0], '1920x1080');
      expect(variants[1], '1280x720');
      expect(variants[2], '854x480');
    });
  });
}

/// Extract resolution from EXT-X-STREAM-INF line
String _extractRes(String infLine) {
  final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(infLine);
  if (resMatch != null) return resMatch.group(1)!;
  final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(infLine);
  if (bwMatch != null) return '${bwMatch.group(1)}bps';
  return 'Auto';
}
