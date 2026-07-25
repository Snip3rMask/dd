package msr.mirudl.app;

import android.content.ContentResolver;
import android.content.Context;
import android.net.Uri;

import androidx.documentfile.provider.DocumentFile;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public final class HlsDownloader {
    public static final int DEFAULT_PARALLEL = 16;
    private static final int MAX_PARALLEL = 32;
    private static final OkHttpClient CLIENT = new OkHttpClient.Builder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .followRedirects(true)
            .followSslRedirects(true)
            .build();

    public interface ProgressListener {
        void onProgress(int percent, int downloaded, int total);
    }

    public interface CancelCheck {
        boolean isCancelled();
    }

    public static String download(Context context, String playlistUrl, String fileName,
                                  int parallelSegments, ProgressListener progress, CancelCheck cancel)
            throws Exception {

        // Resolve master playlist if needed
        String master = getText(playlistUrl);
        if (master.contains("#EXT-X-STREAM-INF")) {
            List<VideoSource> variants = parseMasterPlaylist(master, playlistUrl);
            if (!variants.isEmpty()) {
                playlistUrl = variants.get(0).url;
                master = getText(playlistUrl);
            }
        }

        // Check encryption
        if (master.contains("#EXT-X-KEY")) {
            throw new IOException("Encrypted streams are not supported");
        }

        // Parse segments
        List<String> segments = parseSegments(master, playlistUrl);
        if (segments.isEmpty()) {
            throw new IOException("No HLS segments found");
        }

        // Init map
        String mapUrl = parseInitMap(master, playlistUrl);

        // Create temp dir
        File tempDir = new File(context.getCacheDir(), "hls_" + System.currentTimeMillis());
        if (!tempDir.mkdirs()) throw new IOException("Cannot create temp dir");

        // Download segments in parallel
        downloadSegments(segments, tempDir, clampParallel(parallelSegments), progress, cancel);

        // Determine output
        String cleanName = sanitize(fileName);
        String animeDir = extractParent(fileName);
        Uri treeUri = getDownloadDir(context);
        if (treeUri == null) throw new IOException("Select download folder in Settings");

        DocumentFile outFile = createOutputFile(context, treeUri, animeDir, cleanName + ".mp4");
        OutputStream out = context.getContentResolver().openOutputStream(outFile.getUri(), "w");
        if (out == null) throw new IOException("Cannot open output stream");

        try {
            // Write init segment
            if (mapUrl != null) {
                writeUrlToStream(mapUrl, out);
            }
            // Merge segments
            for (int i = 0; i < segments.size(); i++) {
                File segFile = new File(tempDir, "seg_" + i + ".ts");
                if (segFile.exists()) {
                    try (InputStream in = new java.io.FileInputStream(segFile)) {
                        byte[] buf = new byte[8192];
                        int read;
                        while ((read = in.read(buf)) >= 0) {
                            out.write(buf, 0, read);
                        }
                    }
                }
            }
        } finally {
            out.close();
        }

        // Cleanup
        deleteRecursive(tempDir);

        // Record download
        long size = outFile.length();
        saveDownloadEntry(context, outFile.getUri().toString(), cleanName, animeDir, size);

        return outFile.getUri().toString();
    }

    private static void downloadSegments(List<String> urls, File tempDir, int parallel,
                                          ProgressListener progress, CancelCheck cancel) {
        ExecutorService executor = Executors.newFixedThreadPool(parallel);
        AtomicInteger done = new AtomicInteger(0);
        int total = urls.size();

        for (int i = 0; i < total; i++) {
            final int idx = i;
            executor.execute(() -> {
                if (cancel != null && cancel.isCancelled()) return;
                try {
                    byte[] data = downloadBytes(urls.get(idx));
                    File out = new File(tempDir, "seg_" + idx + ".ts");
                    try (FileOutputStream fos = new FileOutputStream(out)) {
                        fos.write(data);
                    }
                } catch (Exception ignored) {}
                int d = done.incrementAndGet();
                if (progress != null) {
                    progress.onProgress(d * 100 / total, d, total);
                }
            });
        }

        executor.shutdown();
        try {
            executor.awaitTermination(30, TimeUnit.MINUTES);
        } catch (InterruptedException ignored) {}
    }

    // ============ PARSING ============

    private static List<VideoSource> parseMasterPlaylist(String master, String baseUrl) {
        List<VideoSource> list = new ArrayList<>();
        String pending = null;
        for (String raw : master.split("\\r?\\n")) {
            String line = raw.trim();
            if (line.startsWith("#EXT-X-STREAM-INF")) {
                pending = line;
            } else if (pending != null && !line.isEmpty() && !line.startsWith("#")) {
                String res = extractRes(pending);
                String url = resolve(line, baseUrl);
                list.add(new VideoSource(res, url));
                pending = null;
            }
        }
        return list;
    }

    private static List<String> parseSegments(String playlist, String baseUrl) {
        List<String> segments = new ArrayList<>();
        for (String raw : playlist.split("\\r?\\n")) {
            String line = raw.trim();
            if (!line.isEmpty() && !line.startsWith("#")) {
                segments.add(resolve(line, baseUrl));
            }
        }
        return segments;
    }

    private static String parseInitMap(String playlist, String baseUrl) {
        int idx = playlist.indexOf("#EXT-X-MAP:");
        if (idx < 0) return null;
        int uriIdx = playlist.indexOf("URI=\"", idx);
        if (uriIdx < 0) return null;
        int end = playlist.indexOf("\"", uriIdx + 5);
        if (end < 0) return null;
        return resolve(playlist.substring(uriIdx + 5, end), baseUrl);
    }

    // ============ HTTP ============

    private static String getText(String url) throws IOException {
        Request req = new Request.Builder()
                .url(url)
                .header("User-Agent", "Mozilla/5.0")
                .header("Referer", "https://anidb.app/")
                .build();
        try (Response resp = CLIENT.newCall(req).execute()) {
            if (!resp.isSuccessful() || resp.body() == null)
                throw new IOException("HTTP " + resp.code());
            return resp.body().string();
        }
    }

    private static byte[] downloadBytes(String url) {
        try {
            Request req = new Request.Builder().url(url)
                    .header("User-Agent", "Mozilla/5.0").build();
            try (Response resp = CLIENT.newCall(req).execute()) {
                if (resp.isSuccessful() && resp.body() != null)
                    return resp.body().bytes();
            }
        } catch (Exception ignored) {}
        return new byte[0];
    }

    private static void writeUrlToStream(String url, OutputStream out) throws IOException {
        Request req = new Request.Builder().url(url)
                .header("User-Agent", "Mozilla/5.0").build();
        try (Response resp = CLIENT.newCall(req).execute()) {
            if (resp.isSuccessful() && resp.body() != null) {
                try (InputStream in = resp.body().byteStream()) {
                    byte[] buf = new byte[8192];
                    int read;
                    while ((read = in.read(buf)) >= 0) out.write(buf, 0, read);
                }
            }
        }
    }

    // ============ FILE HELPERS ============

    private static Uri getDownloadDir(Context context) {
        return StorageSettings.getDownloadUri(context);
    }

    private static DocumentFile createOutputFile(Context context, Uri treeUri,
                                                  String folderName, String fileName) throws IOException {
        DocumentFile root = DocumentFile.fromTreeUri(context, treeUri);
        if (root == null || !root.canWrite())
            throw new IOException("Cannot write to download folder");

        DocumentFile anime = findOrCreateDir(root, sanitize(folderName));
        if (anime == null) throw new IOException("Cannot create anime folder");

        DocumentFile existing = anime.findFile(fileName);
        if (existing != null) existing.delete();

        DocumentFile file = anime.createFile("video/mp4", fileName);
        if (file == null) throw new IOException("Cannot create output file");
        return file;
    }

    private static DocumentFile findOrCreateDir(DocumentFile parent, String name) {
        DocumentFile existing = parent.findFile(name);
        if (existing != null && existing.isDirectory()) return existing;
        return parent.createDirectory(name);
    }

    private static void saveDownloadEntry(Context context, String uri, String title,
                                           String parent, long size) {
        try {
            DownloadEntryStore.Entry entry = new DownloadEntryStore.Entry();
            entry.uri = uri;
            entry.title = title;
            entry.parent = parent;
            entry.size = size;
            entry.completedAt = System.currentTimeMillis();
            DownloadEntryStore.add(context, entry);
        } catch (Exception ignored) {}
    }

    private static void deleteRecursive(File file) {
        if (file == null || !file.exists()) return;
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null)
                for (File child : children) deleteRecursive(child);
        }
        file.delete();
    }

    private static String sanitize(String value) {
        if (value == null || value.isEmpty()) return "Unknown";
        String cleaned = value.replaceAll("[\\\\/:*?\"<>|]+", " ")
                .replaceAll("\\s+", " ").trim();
        return cleaned.length() > 80 ? cleaned.substring(0, 80).trim() : cleaned;
    }

    private static String extractParent(String fileName) {
        if (fileName == null) return "Unknown";
        int idx = fileName.indexOf(" - Episode");
        return idx > 0 ? fileName.substring(0, idx) : fileName;
    }

    private static String extractRes(String infLine) {
        int idx = infLine.indexOf("RESOLUTION=");
        if (idx >= 0) {
            int end = infLine.indexOf(",", idx);
            return end > 0 ? infLine.substring(idx + 11, end) : infLine.substring(idx + 11);
        }
        return "Auto";
    }

    private static String resolve(String value, String base) {
        if (value.startsWith("http://") || value.startsWith("https://")) return value;
        if (value.startsWith("/")) {
            int slash = base.indexOf("/", 8);
            return (slash > 0 ? base.substring(0, slash) : base) + value;
        }
        int slash = base.lastIndexOf("/");
        return (slash > 0 ? base.substring(0, slash + 1) : base + "/") + value;
    }

    private static int clampParallel(int value) {
        if (value < 1) return 1;
        return Math.min(value, MAX_PARALLEL);
    }
}
