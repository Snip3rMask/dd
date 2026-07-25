# MiruDL

**MiruDL** — Direct HLS downloader for **anidb.app**. Android app to search, browse, and download anime episodes.

## Features

- **Search** — Search any anime on AniDB
- **Browse Episodes** — View all episodes with IDs
- **Direct HLS Download** — Downloads HLS segments in parallel and merges to `.mp4`
- **Background Download** — Foreground service with notification progress
- **Batch Download** — Download all episodes sequentially
- **Quality Selection** — 1080p, 720p, 480p, 360p, Auto
- **Language Selection** — Sub (Japanese) or Dub (English)
- **Flexible Storage** — Pick any folder via SAF (Storage Access Framework)
- **Multi-device** — Adaptive layout for phones, tablets, TVs, Chromebooks

## Download

Download the latest APK from [Releases](https://github.com/msrofficial/MiruDL-App/releases).

| Architecture | Devices |
|-------------|---------|
| `Universal` | All devices (larger APK) |
| `arm64-v8a` | Modern phones, tablets, TVs (recommended) |
| `armeabi-v7a` | Older devices |
| `x86_64` | Chromebooks, emulators |
| `x86` | Older emulators |

## Build from Source

### Prerequisites
- Android Studio Hedgehog (2023.1.1+) or JDK 17
- Android SDK 34

### Clone & Build
```bash
git clone https://github.com/msrofficial/MiruDL-App.git
cd MiruDL-App
./gradlew assembleRelease
```
APK will be at `app/build/outputs/apk/release/`

## How It Works

1. **Search** — Calls `anidb.app/search/suggestions?q=` to find anime
2. **Episodes** — Fetches `anidb.app/api/frontend/anime/{id}/episodes`
3. **Sources** — Gets embed URLs from `anidb.app/api/frontend/episode/{id}/languages`
4. **HLS** — Extracts `.m3u8` URL from the embed page's JW Player config
5. **Download** — Downloads HLS segments in parallel (default 16), merges to `.mp4`
6. **Save** — Saves to user-selected folder via SAF

## Architecture

```
app/src/main/java/msr/mirudl/app/
├── MainActivity.java        → Search screen
├── DetailActivity.java      → Episode list & download
├── DownloadsActivity.java   → Active & completed downloads
├── SettingsActivity.java    → Folder picker, quality, language
├── AniDbApi.java            → AniDB REST API client
├── HlsDownloader.java       → HLS segment download & merge
├── DownloadService.java     → Background download service
├── DownloadManager.java     → Download queue management
├── DownloadEntryStore.java  → Completed downloads persistence
└── StorageSettings.java     → SharedPreferences wrapper
```

## License

MIT
