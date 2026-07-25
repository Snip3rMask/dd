import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/get_qualities.dart';
import 'package:mirudl_flutter/data/models/video_source.dart';

class MockRepo extends AnimeRepository {
  MockRepo() ;

  @override
  Future<List<VideoSource>> getQualities(String masterUrl) async {
    return [
      VideoSource(quality: '1920x1080', url: 'https://example.com/1080.m3u8'),
      VideoSource(quality: '1280x720', url: 'https://example.com/720.m3u8'),
      VideoSource(quality: '854x480', url: 'https://example.com/480.m3u8'),
    ];
  }
}

void main() {
  late GetQualities useCase;

  setUp(() {
    useCase = GetQualities(MockRepo());
  });

  test('returns quality variants', () async {
    final result = await useCase.call('https://example.com/master.m3u8');
    expect(result, hasLength(3));
    expect(result[0].quality, '1920x1080');
    expect(result[1].quality, '1280x720');
  });
}
