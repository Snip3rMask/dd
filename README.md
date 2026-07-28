<p align="center">
  <img src="app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png" width="120" height="120" alt="MiruDL Logo">
</p>

<h1 align="center">🎬 MiruDL</h1>

<p align="center">
  <strong>A lightweight anime downloader for Android</strong>
  <br>
  Browse, search, and download your favorite anime episodes directly to your phone.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-21%2B-3DDC84?logo=android" alt="Android 21+">
  <img src="https://img.shields.io/badge/API-34-blue" alt="API 34">
  <img src="https://img.shields.io/badge/Java-17-orange?logo=openjdk" alt="Java 17">
  <img src="https://img.shields.io/badge/Gradle-8.9-brightgreen?logo=gradle" alt="Gradle 8.9">
  <img src="https://img.shields.io/badge/license-MIT-yellow" alt="MIT License">
</p>

---

## 📖 What is MiruDL?

**MiruDL** (read: *Miru Download*) is a simple, fast, and free Android app for downloading anime episodes. 

It scrapes data from **anidb.app**, fetches episode lists, resolves HLS (m3u8) video streams, and downloads them directly to your device storage — all in **parallel segments** for maximum speed.

> No ads. No accounts. No tracking. Just pure anime downloading.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 **Search** | Search thousands of anime titles instantly |
| 📋 **Episode list** | View all episodes with numbers & filler markers |
| ⬇️ **Download** | Download any episode with one tap |
| 📦 **Download All** | Batch-download entire series at once |
| ⚡ **Fast download** | Parallel segment download (up to 32 threads) |
| 🎞️ **Quality select** | Auto / 360p / 480p / 720p / 1080p |
| 🌐 **Multi-language** | Sub (Japanese) or Dub (English) audio |
| 🌙 **Dark theme** | Built-in dark & light mode |
| 📁 **Custom folder** | Choose where to save downloads |
| 📊 **Download manager** | Track progress, pause, cancel, resume |
| 📜 **Download history** | View all completed downloads |
| 📱 **Material Design** | Clean, modern Android UI |

---

## 📸 Screenshots

_(Add your screenshots here)_

| Home | Detail | Downloads | Settings |
|------|--------|-----------|----------|
| ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) | ![Downloads](screenshots/downloads.png) | ![Settings](screenshots/settings.png) |

---

## 🚀 How to Use

### 1️⃣ Search Anime
Open the app → Type an anime name in the search bar → Tap search.

### 2️⃣ Pick a Series
Browse the results → Tap on the anime you want.

### 3️⃣ Choose Episodes
You'll see all available episodes → Tap any episode to download.

### 4️⃣ Select Quality
Choose your preferred quality — **Auto, 360p, 480p, 720p, or 1080p**.

### 5️⃣ Done!
The download starts automatically. Track progress from the **Downloads** tab or notification bar.

---

## 🔧 Installation

### 📲 Download APK
Grab the latest APK from the [Releases](https://github.com/Snip3rMask/dd/releases) page and install it on your Android device.

> **Minimum requirement:** Android 5.0 (API 21) or higher.

### 🏗️ Build from Source

```bash
# Clone the repository
git clone https://github.com/Snip3rMask/dd.git
cd dd

# Build the APK (Linux / macOS)
./gradlew assembleDebug

# Or on Windows
gradlew.bat assembleDebug

# The APK will be at:
# app/build/outputs/apk/debug/app-arm64-v8a-debug.apk
```

---

## ⚙️ App Settings

| Setting | Description |
|---------|-------------|
| **Download Folder** | Choose where videos are saved |
| **Download Speed** | Set parallel segments (Slow → Very Fast) |
| **Preferred Quality** | Default quality for all downloads |
| **Audio Language** | Sub (Japanese) or Dub (English) |
| **Dark Theme** | Toggle dark/light mode |

---

## 🧰 Tech Stack

- **Language:** Java
- **Build:** Gradle 8.9 + Android Gradle Plugin 8.7.3
- **Minimum SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)
- **Networking:** OkHttp 4.12.0
- **JSON:** Gson 2.10.1
- **Images:** Glide 4.16.0
- **UI:** Material Components, AndroidX, RecyclerView, CardView

---

## 📁 Project Structure

```
app/
├── src/main/java/msr/mirudl/app/
│   ├── MainActivity.java        ← Main screen (search + tabs)
│   ├── DetailActivity.java      ← Anime detail + episodes
│   ├── DownloadsActivity.java   ← Download history
│   ├── SettingsActivity.java    ← App settings
│   ├── AboutActivity.java       ← About page
│   ├── DeveloperActivity.java   ← Developer info
│   ├── MiruClient.java          ← API client
│   ├── HlsDownloader.java       ← HLS download engine
│   ├── DownloadManager.java     ← Download job queue
│   ├── DownloadService.java     ← Foreground download service
│   └── ... more classes ...
```

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request:

1. 🐛 [Open an issue](https://github.com/Snip3rMask/dd/issues)
2. 🍴 Fork the repo
3. 🔧 Make your changes
4. 📬 Submit a pull request

---

## 📄 License

This project is open source. Feel free to use, modify, and share.

---

## 👤 Developer

- **GitHub:** [@Snip3rMask](https://github.com/Snip3rMask)
- **Built with ❤️ for the anime community**

---

<p align="center">
  <b>MiruDL</b> — <i>Miru (見る) means "to watch" in Japanese. Download and watch anytime, anywhere.</i>
</p>
