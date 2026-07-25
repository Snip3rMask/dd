import '../../data/repositories/anime_repository.dart';
import '../../data/models/anime_item.dart';

class SearchAnime {
  final AnimeRepository _repository;
  SearchAnime(this._repository);

  Future<List<AnimeItem>> call(String query) async {
    if (query.trim().isEmpty) return [];
    return await _repository.searchAnime(query.trim());
  }
}
