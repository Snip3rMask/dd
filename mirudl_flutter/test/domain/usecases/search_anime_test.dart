import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/search_anime.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';
import 'package:mirudl_flutter/data/models/anime_item.dart';
import 'package:mirudl_flutter/core/errors/exceptions.dart';
import 'package:mirudl_flutter/core/errors/failures.dart';

class MockRepo extends AnimeRepository {
  MockRepo() : super(null!);

  @override
  Future<List<AnimeItem>> searchAnime(String query) async {
    if (query == 'naruto') {
      return [AnimeItem(id: '1', title: 'Naruto')];
    }
    if (query == 'error') {
      throw ServerFailure('API Error');
    }
    return [];
  }
}

void main() {
  late SearchAnime useCase;

  setUp(() {
    useCase = SearchAnime(MockRepo());
  });

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
    expect(
      () => useCase.call('error'),
      throwsA(isA<ServerFailure>()),
    );
  });
}
