import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../data/datasources/local/download_store.dart';
import '../data/datasources/local/storage_helper.dart';
import '../data/datasources/remote/anidb_api.dart';
import '../data/repositories/anime_repository.dart';
import '../data/repositories/download_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/usecases/download_episode.dart';
import '../domain/usecases/get_download_history.dart';
import '../domain/usecases/get_episodes.dart';
import '../domain/usecases/get_languages.dart';
import '../domain/usecases/get_qualities.dart';
import '../domain/usecases/resolve_hls.dart';
import '../domain/usecases/search_anime.dart';
import '../presentation/providers/search_provider.dart';
import '../presentation/providers/detail_provider.dart';
import '../presentation/providers/downloads_provider.dart';
import '../presentation/providers/settings_provider.dart';
import '../services/hls_downloader_service.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Core ─────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // ─── Data Sources ─────────────────────────────────────────────
  final storageHelper = StorageHelper();
  await storageHelper.init();
  sl.registerLazySingleton<StorageHelper>(() => storageHelper);

  final downloadStore = DownloadStore();
  await downloadStore.init();
  sl.registerLazySingleton<DownloadStore>(() => downloadStore);

  sl.registerLazySingleton<AniDbApi>(
      () => AniDbApi(sl<ApiClient>()));

  // ─── Repositories ─────────────────────────────────────────────
  sl.registerLazySingleton<AnimeRepository>(
      () => AnimeRepository(sl<AniDbApi>()));
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepository(sl<StorageHelper>()));
  sl.registerLazySingleton<DownloadRepository>(
      () => DownloadRepository(sl<DownloadStore>()));

  // ─── Domain Use Cases ─────────────────────────────────────────
  sl.registerLazySingleton<SearchAnime>(
      () => SearchAnime(sl<AnimeRepository>()));
  sl.registerLazySingleton<GetEpisodes>(
      () => GetEpisodes(sl<AnimeRepository>()));
  sl.registerLazySingleton<GetLanguages>(
      () => GetLanguages(sl<AnimeRepository>()));
  sl.registerLazySingleton<ResolveHls>(
      () => ResolveHls(sl<AnimeRepository>()));
  sl.registerLazySingleton<GetQualities>(
      () => GetQualities(sl<AnimeRepository>()));
  sl.registerLazySingleton<DownloadEpisode>(
      () => DownloadEpisode(sl<DownloadRepository>()));
  sl.registerLazySingleton<GetDownloadHistory>(
      () => GetDownloadHistory(sl<DownloadRepository>()));

  // ─── Services ─────────────────────────────────────────────────
  sl.registerLazySingleton<HlsDownloaderService>(
      () => HlsDownloaderService());

  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  final backgroundService = BackgroundService(
    repository: sl<DownloadRepository>(),
    hlsDownloader: sl<HlsDownloaderService>(),
    notificationService: sl<NotificationService>(),
  );
  sl.registerLazySingleton<BackgroundService>(() => backgroundService);

  // ─── Providers (ViewModels) ───────────────────────────────────
  sl.registerFactory<SearchProvider>(
      () => SearchProvider(sl<SearchAnime>()));
  sl.registerFactory<DetailProvider>(() => DetailProvider(
        sl<GetEpisodes>(),
        sl<GetLanguages>(),
        sl<ResolveHls>(),
        sl<GetQualities>(),
        sl<DownloadEpisode>(),
        sl<SettingsRepository>(),
        sl<BackgroundService>(),
      ));
  sl.registerFactory<DownloadsProvider>(
      () => DownloadsProvider(sl<DownloadRepository>()));
  sl.registerFactory<SettingsProvider>(
      () => SettingsProvider(sl<SettingsRepository>()));
}
