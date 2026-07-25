import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/get_languages.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';

class MockRepo extends AnimeRepository {
  MockRepo() ;

  @override
  Future<List<VideoSource>> getEpisodeLanguages(int episodeId) async {
    return [
      VideoSource(quality: 'Sub (Japanese)', url: 'embed1', language: 'jpn', server: 'AniDB'),
      VideoSource(quality: 'Dub (English)', url: 'embed2', language: 'eng', server: 'AniDB'),
    ];
  }
}

void main() {
  late GetLanguages useCase;

  setUp(() {
    useCase = GetLanguages(MockRepo());
  });

  test('returns language sources for episode', () async {
    final result = await useCase.call(1);
    expect(result, hasLength(2));
    expect(result.first.language, 'jpn');
    expect(result.last.language, 'eng');
  });
}
