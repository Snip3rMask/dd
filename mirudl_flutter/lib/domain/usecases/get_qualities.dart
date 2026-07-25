import '../../data/repositories/anime_repository.dart';
import '../../data/models/video_source.dart';

class GetQualities {
  final AnimeRepository _repository;
  GetQualities(this._repository);

  Future<List<VideoSource>> call(String masterUrl) async {
    return await _repository.getQualities(masterUrl);
  }
}
