import '../../data/repositories/anime_repository.dart';
import '../../data/models/episode_item.dart';

class GetEpisodes {
  final AnimeRepository _repository;
  GetEpisodes(this._repository);

  Future<List<EpisodeItem>> call(String animeId) async {
    return await _repository.getEpisodes(animeId);
  }
}
