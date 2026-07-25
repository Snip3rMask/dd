import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/get_languages.dart';
import 'package:mirudl_flutter/core/network/api_client.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';

class _MockApi extends AniDbApi {
  _MockApi() : super(ApiClient());
  @override
  Future<List<VideoSource>> getEpisodeLanguages(int episodeId) async {
    return [VideoSource(quality: 'Sub', url: 'url1', language: 'jpn', server: 'AniDB')];
  }
}

class MockRepo extends AnimeRepository {
  MockRepo() : super(_MockApi());
}

void main() {
  late GetLanguages useCase;
  setUp(() { useCase = GetLanguages(MockRepo()); });
  test('returns language sources for episode', () async {
    final result = await useCase.call(1);
    expect(result, hasLength(1));
    expect(result.first.language, 'jpn');
  });
}
