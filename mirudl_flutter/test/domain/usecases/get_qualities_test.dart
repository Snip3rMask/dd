import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/get_qualities.dart';
import 'package:mirudl_flutter/core/network/api_client.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';

class _MockApi extends AniDbApi {
  _MockApi() : super(ApiClient());
  @override
  Future<List<VideoSource>> getQualities(String masterUrl) async {
    return [VideoSource(quality: '1920x1080', url: 'https://1080.m3u8')];
  }
}

class MockRepo extends AnimeRepository {
  MockRepo() : super(_MockApi());
}

void main() {
  late GetQualities useCase;
  setUp(() { useCase = GetQualities(MockRepo()); });
  test('returns quality variants', () async {
    final result = await useCase.call('https://example.com/master.m3u8');
    expect(result, hasLength(1));
    expect(result[0].quality, '1920x1080');
  });
}
