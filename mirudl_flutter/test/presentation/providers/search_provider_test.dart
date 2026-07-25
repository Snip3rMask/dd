import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/presentation/providers/search_provider.dart';
import 'package:mirudl_flutter/domain/usecases/search_anime.dart';
import 'package:mirudl_flutter/data/models/anime_item.dart';

class MockUseCase extends SearchAnime {
  MockUseCase() ;

  @override
  Future<List<AnimeItem>> call(String query) async {
    if (query == 'naruto') {
      return [AnimeItem(id: '1', title: 'Naruto'), AnimeItem(id: '2', title: 'Naruto Shippuden')];
    }
    if (query == 'error') {
      throw Exception('Network error');
    }
    return [];
  }
}

void main() {
  late SearchProvider provider;

  setUp(() {
    provider = SearchProvider(MockUseCase());
  });

  test('initial state is empty', () {
    expect(provider.results, isEmpty);
    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.query, '');
  });

  test('search returns results', () async {
    await provider.search('naruto');

    expect(provider.isLoading, false);
    expect(provider.results, hasLength(2));
    expect(provider.query, 'naruto');
    expect(provider.error, isNull);
  });

  test('search with empty query clears results', () async {
    await provider.search('naruto');
    expect(provider.results, isNotEmpty);

    await provider.search('');
    expect(provider.results, isEmpty);
    expect(provider.query, '');
  });

  test('search handles errors gracefully', () async {
    await provider.search('error');

    expect(provider.isLoading, false);
    expect(provider.results, isEmpty);
    expect(provider.error, isNotNull);
  });

  test('clear resets state', () async {
    await provider.search('naruto');
    expect(provider.results, isNotEmpty);

    provider.clear();
    expect(provider.results, isEmpty);
    expect(provider.query, '');
    expect(provider.error, isNull);
  });
}
