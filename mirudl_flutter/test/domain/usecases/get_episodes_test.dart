import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/get_episodes.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/models/episode_item.dart';

class MockRepo extends AnimeRepository {
  MockRepo() ;

  @override
  Future<List<EpisodeItem>> getEpisodes(String animeId) async {
    if (animeId == '42') {
      return [
        EpisodeItem(id: 1, number: 1, title: 'Ep1'),
        EpisodeItem(id: 2, number: 2, title: 'Ep2'),
      ];
    }
    return [];
  }
}

void main() {
  late GetEpisodes useCase;

  setUp(() {
    useCase = GetEpisodes(MockRepo());
  });

  test('returns episodes for valid anime ID', () async {
    final result = await useCase.call('42');
    expect(result, hasLength(2));
    expect(result.first.title, 'Ep1');
  });

  test('returns empty for invalid anime ID', () async {
    final result = await useCase.call('invalid');
    expect(result, isEmpty);
  });
}
