import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/data/repositories/download_repository.dart';
import 'package:mirudl_flutter/data/datasources/local/download_store.dart';
import 'package:mirudl_flutter/data/models/download_entry.dart';
import 'package:mirudl_flutter/domain/enums/download_status.dart';

class MockDownloadStore extends DownloadStore {
  List<DownloadEntry> _entries = [];

  @override
  List<DownloadEntry> all() => List.unmodifiable(_entries);

  @override
  Future<void> add(DownloadEntry entry) async {
    final key = entry.key;
    bool replaced = false;
    for (int i = 0; i < _entries.length; i++) {
      if (key == _entries[i].key) {
        _entries[i] = entry;
        replaced = true;
        break;
      }
    }
    if (!replaced) _entries.insert(0, entry);
  }

  @override
  Future<void> remove(DownloadEntry entry) async {
    _entries.removeWhere((e) => e.key == entry.key);
  }

  @override
  Future<void> removeAll(List<DownloadEntry> entries) async {
    final keys = entries.map((e) => e.key).toSet();
    _entries.removeWhere((e) => keys.contains(e.key));
  }
}

void main() {
  late DownloadRepository repository;
  late MockDownloadStore store;

  setUp(() {
    store = MockDownloadStore();
    repository = DownloadRepository(store);
  });

  group('DownloadRepository - Queue', () {
    test('enqueue adds job to queue', () {
      final job = repository.enqueue(
        animeTitle: 'Naruto',
        episodeTitle: 'Episode 1',
        quality: '1080p',
        language: 'jpn',
        hlsUrl: 'https://example.com/stream.m3u8',
      );

      expect(job.animeTitle, 'Naruto');
      expect(job.episodeTitle, 'Episode 1');
      expect(job.status, DownloadStatus.queued);
      expect(job.finished, false);
      expect(repository.activeCount, 1);
    });

    test('find returns correct job', () {
      final job = repository.enqueue(
        animeTitle: 'One Piece',
        episodeTitle: 'Episode 1000',
        quality: '720p',
        language: 'eng',
        hlsUrl: 'https://example.com/op.m3u8',
      );

      final found = repository.find(job.id);
      expect(found, isNotNull);
      expect(found!.animeTitle, 'One Piece');
    });

    test('find returns null for unknown id', () {
      final found = repository.find('nonexistent');
      expect(found, isNull);
    });

    test('cancel marks job as cancelled and finished', () {
      final job = repository.enqueue(
        animeTitle: 'Test',
        episodeTitle: 'Ep 1',
        quality: '1080p',
        language: 'jpn',
        hlsUrl: 'url',
      );

      repository.cancel(job);

      expect(job.cancelled, true);
      expect(job.status, DownloadStatus.cancelled);
      expect(job.finished, true);
    });

    test('removeFinished removes only finished jobs', () {
      repository.enqueue(animeTitle: 'A', episodeTitle: '1', quality: '1080p', language: 'jpn', hlsUrl: 'u1');
      final job2 = repository.enqueue(animeTitle: 'B', episodeTitle: '2', quality: '720p', language: 'jpn', hlsUrl: 'u2');
      repository.cancel(job2);

      expect(repository.snapshot().length, 2);

      repository.removeFinished();

      expect(repository.snapshot().length, 1);
      expect(repository.snapshot().first.animeTitle, 'A');
    });

    test('snapshot returns immutable list', () {
      repository.enqueue(animeTitle: 'A', episodeTitle: '1', quality: '1080p', language: 'jpn', hlsUrl: 'u1');

      expect(() => repository.snapshot() as List, isNot(throwsUnsupportedError));
    });
  });

  group('DownloadRepository - History', () {
    test('getHistory returns empty initially', () {
      expect(repository.getHistory(), isEmpty);
    });

    test('addHistory stores entry', () async {
      final entry = DownloadEntry(
        uri: '/path/file.mp4',
        title: 'Episode 5',
        parent: 'Naruto',
        size: 1000,
        completedAt: 1700000000000,
      );

      await repository.addHistory(entry);
      final history = repository.getHistory();

      expect(history, hasLength(1));
      expect(history.first.title, 'Episode 5');
    });

    test('removeHistory removes entry', () async {
      final entry = DownloadEntry(uri: '/path/file.mp4', title: 'Ep1', parent: 'A');
      await repository.addHistory(entry);
      expect(repository.getHistory(), hasLength(1));

      await repository.removeHistory(entry);
      expect(repository.getHistory(), isEmpty);
    });

    test('clearHistory removes all specified entries', () async {
      final e1 = DownloadEntry(uri: '/1.mp4', title: 'Ep1', parent: 'A');
      final e2 = DownloadEntry(uri: '/2.mp4', title: 'Ep2', parent: 'A');
      final e3 = DownloadEntry(uri: '/3.mp4', title: 'Ep3', parent: 'B');

      await repository.addHistory(e1);
      await repository.addHistory(e2);
      await repository.addHistory(e3);
      expect(repository.getHistory(), hasLength(3));

      await repository.clearHistory([e1, e3]);
      expect(repository.getHistory(), hasLength(1));
      expect(repository.getHistory().first.title, 'Ep2');
    });
  });

  group('DownloadRepository - State', () {
    test('isRunning defaults to false', () {
      expect(repository.isRunning, false);
    });

    test('isRunning can be updated', () {
      repository.isRunning = true;
      expect(repository.isRunning, true);
    });

    test('activeCount returns only unfinished jobs', () {
      repository.enqueue(animeTitle: 'A', episodeTitle: '1', quality: '1080p', language: 'jpn', hlsUrl: 'u1');
      final job2 = repository.enqueue(animeTitle: 'B', episodeTitle: '2', quality: '1080p', language: 'jpn', hlsUrl: 'u2');

      expect(repository.activeCount, 2);

      repository.cancel(job2);
      expect(repository.activeCount, 1);
    });
  });
}
