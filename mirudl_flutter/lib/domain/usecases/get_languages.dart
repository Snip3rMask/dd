import '../../data/repositories/anime_repository.dart';
import '../../data/models/video_source.dart';

class GetLanguages {
  final AnimeRepository _repository;
  GetLanguages(this._repository);

  Future<List<VideoSource>> call(int episodeId) async {
    return await _repository.getEpisodeLanguages(episodeId);
  }
}
