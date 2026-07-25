import 'package:flutter_test/flutter_test.dart';
import 'package:mirudl_flutter/domain/usecases/resolve_hls.dart';
import 'package:mirudl_flutter/data/repositories/anime_repository.dart';
import 'package:mirudl_flutter/core/network/api_client.dart';
import 'package:mirudl_flutter/data/datasources/remote/anidb_api.dart';

/// Mock that doesn't need real ApiClient
class _MockApi extends AniDbApi {
  _MockApi() : super(ApiClient()); // Bypass constructor

  @override
  Future<String?> resolveHlsFromEmbed(String embedUrl) async {
    if (embedUrl.contains('valid')) {
      return 'https://example.com/master.m3u8';
    }
    return null;
  }
}

class MockRepo extends AnimeRepository {
  MockRepo() : super(_MockApi());
}

void main() {
  late ResolveHls useCase;

  setUp(() {
    useCase = ResolveHls(MockRepo());
  });

  test('returns HLS URL for valid embed URL', () async {
    final result = await useCase.call('https://anidb.app/embed/valid');
    expect(result, 'https://example.com/master.m3u8');
  });

  test('returns null for invalid embed URL', () async {
    final result = await useCase.call('https://anidb.app/embed/invalid');
    expect(result, isNull);
  });
}
