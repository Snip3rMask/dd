import '../../data/repositories/anime_repository.dart';

class ResolveHls {
  final AnimeRepository _repository;
  ResolveHls(this._repository);

  Future<String?> call(String embedUrl) async {
    return await _repository.resolveHlsFromEmbed(embedUrl);
  }
}
