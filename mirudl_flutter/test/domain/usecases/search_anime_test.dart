import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/search_anime.dart';
import 'package:mirudl_flutter/core/network/api_client.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';
import 'package:mirudl_flutter/data/models/anime_item.dart';
import 'package:mirudl_flutter/core/errors/failures.dart';

class _MockApi extends AniDbApi {
  _MockApi() : super(ApiClient());
  @override
  Future<List<AnimeItem>> search(String query) async {
    if (query == 'naruto') return [AnimeItem(id: '1', title: 'Naruto')];
    if (query == 'error') throw Exception('API Error');
    return [];
  }
}

class MockRepo extends AnimeRepository {
  MockRepo() : super(_MockApi());
}

void main() {
  late SearchAnime useCase;
  setUp(() { useCase = SearchAnime(MockRepo()); });

  test('returns results for valid query', () async {
    final result = await useCase.call('naruto');
    expect(result, hasLength(1));
    expect(result.first.title, 'Naruto');
  });
  test('returns empty for empty query', () async {
    final result = await useCase.call('');
    expect(result, isEmpty);
  });
  test('returns empty for whitespace query', () async {
    final result = await useCase.call('   ');
    expect(result, isEmpty);
  });
  test('throws on error', () async {
    expect(() => useCase.call('error'), throwsA(isA<Exception>()));
  });
}
