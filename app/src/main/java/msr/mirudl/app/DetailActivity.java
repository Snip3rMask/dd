package msr.mirudl.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class DetailActivity extends BaseActivity {
    private String animeId, animeTitle, animeThumb;
    private RecyclerView episodeList;
    private ProgressBar loadingBar;
    private TextView titleText, emptyText, episodeCount, detailMeta, detailDesc, detailStatus;
    private EpisodeAdapter adapter;

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final AniDbApi api = AniDbApi.getInstance();
    private List<EpisodeItem> episodes = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_detail);

        animeId = getIntent().getStringExtra("anime_id");
        animeTitle = getIntent().getStringExtra("anime_title");
        animeThumb = getIntent().getStringExtra("anime_thumb");

        titleText = findViewById(R.id.detail_title);
        episodeList = findViewById(R.id.episode_list);
        loadingBar = findViewById(R.id.loading_bar);
        emptyText = findViewById(R.id.empty_text);
        episodeCount = findViewById(R.id.episode_count);
        detailMeta = findViewById(R.id.detail_meta);
        detailDesc = findViewById(R.id.detail_description);
        detailStatus = findViewById(R.id.detail_status);

        ImageView thumbView = findViewById(R.id.detail_thumb);
        TextView titleView = findViewById(R.id.detail_title_text);

        titleText.setText(animeTitle);
        if (titleView != null) titleView.setText(animeTitle);

        if (animeThumb != null && !animeThumb.isEmpty()) {
            Glide.with(this).load(animeThumb).centerCrop().into(thumbView);
        }

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());

        // Download All button
        findViewById(R.id.btn_download_all).setOnClickListener(v -> {
            if (episodes.isEmpty()) {
                Toast.makeText(this, "No episodes available", Toast.LENGTH_SHORT).show();
                return;
            }
            if (!StorageSettings.hasDownloadUri(this)) {
                new AlertDialog.Builder(this)
                        .setTitle("Select Download Folder")
                        .setMessage("Please select a download folder first in Settings")
                        .setPositiveButton("Open Settings", (d, w) ->
                                startActivity(new Intent(this, SettingsActivity.class)))
                        .setNegativeButton("Cancel", null)
                        .show();
                return;
            }
            new AlertDialog.Builder(this)
                    .setTitle("Download All Episodes")
                    .setMessage("Start downloading all " + episodes.size() + " episodes?")
                    .setPositiveButton("Download All", (d, w) -> downloadAllEpisodes())
                    .setNegativeButton("Cancel", null)
                    .show();
        });

        adapter = new EpisodeAdapter(ep -> {
            if (ep.hlsUrl != null) {
                startDownload(ep);
            } else {
                resolveAndDownload(ep);
            }
        });

        episodeList.setLayoutManager(new LinearLayoutManager(this));
        episodeList.setAdapter(adapter);

        loadEpisodes();
        loadDetails();
    }

    private void loadDetails() {
        executor.execute(() -> {
            try {
                // Try to get more info from detail page
                String title = api.getAnimeTitle(animeId);
                if (title != null && !title.isEmpty()) {
                    String finalTitle = title;
                    handler.post(() -> {
                        titleText.setText(finalTitle);
                        TextView tv = findViewById(R.id.detail_title_text);
                        if (tv != null) tv.setText(finalTitle);
                    });
                }
            } catch (Exception ignored) {}
        });
    }

    private void loadEpisodes() {
        loadingBar.setVisibility(View.VISIBLE);
        executor.execute(() -> {
            try {
                episodes = api.getEpisodes(animeId);
                handler.post(() -> {
                    loadingBar.setVisibility(View.GONE);
                    String count = episodes.size() + " episodes";
                    episodeCount.setText(count);
                    adapter.setItems(episodes);
                    if (episodes.isEmpty()) {
                        emptyText.setVisibility(View.VISIBLE);
                    }
                });
            } catch (Exception e) {
                handler.post(() -> {
                    loadingBar.setVisibility(View.GONE);
                    emptyText.setText("Error: " + e.getMessage());
                    emptyText.setVisibility(View.VISIBLE);
                });
            }
        });
    }

    private void resolveAndDownload(EpisodeItem ep) {
        executor.execute(() -> {
            try {
                List<VideoSource> langs = api.getEpisodeLanguages(ep.id);
                if (langs.isEmpty()) {
                    handler.post(() -> Toast.makeText(this, "No sources found", Toast.LENGTH_SHORT).show());
                    return;
                }
                String prefLang = StorageSettings.getPreferredLanguage(this);
                VideoSource selected = null;
                for (VideoSource vs : langs) {
                    if (vs.language.equals(prefLang)) { selected = vs; break; }
                }
                if (selected == null) selected = langs.get(0);

                String hlsUrl = api.resolveHlsFromEmbed(selected.url);
                if (hlsUrl == null) {
                    handler.post(() -> Toast.makeText(this, "No HLS URL found", Toast.LENGTH_SHORT).show());
                    return;
                }

                ep.hlsUrl = hlsUrl;
                ep.language = selected.language;
                ep.langName = selected.quality;
                ep.embedUrl = selected.url;

                handler.post(() -> startDownload(ep));
            } catch (Exception e) {
                handler.post(() -> Toast.makeText(this, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show());
            }
        });
    }

    private void startDownload(EpisodeItem ep) {
        if (!StorageSettings.hasDownloadUri(this)) {
            new AlertDialog.Builder(this)
                    .setTitle("Select Download Folder")
                    .setMessage("Please select a download folder first in Settings")
                    .setPositiveButton("Go to Settings", (d, w) ->
                            startActivity(new Intent(this, SettingsActivity.class)))
                    .setNegativeButton("Cancel", null)
                    .show();
            return;
        }


        String quality = StorageSettings.getPreferredQuality(this);
        String language = ep.language != null ? ep.language : "jpn";
        String hlsUrl = ep.hlsUrl;

        executor.execute(() -> {
            try {
                List<VideoSource> variants = api.getQualities(hlsUrl);
                String finalUrl = hlsUrl;
                // Auto-pick preferred quality from Settings — no dialog needed
                for (VideoSource v : variants) {
                    if (v.quality.contains(quality.replace("p", ""))) {
                        finalUrl = v.url;
                        break;
                    }
                }
                queueDownload(ep, finalUrl, quality, language);
            } catch (Exception e) {
                queueDownload(ep, hlsUrl, quality, language);
            }
        });
    }

    private void queueDownload(EpisodeItem ep, String hlsUrl, String quality, String language) {
        DownloadManager.Job job = DownloadManager.enqueue(
                animeTitle, "Episode " + ep.getLabel(), quality, language, hlsUrl
        );
        adapter.notifyDataSetChanged();

        List<DownloadManager.Job> jobs = new ArrayList<>();
        jobs.add(job);
        Intent intent = DownloadService.startIntent(this, jobs);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent);
        } else {
            startService(intent);
        }

        Toast.makeText(this, "Queued: Episode " + ep.getLabel(), Toast.LENGTH_SHORT).show();
    }

    private void downloadAllEpisodes() {
        executor.execute(() -> {
            try {
                List<DownloadManager.Job> jobs = new ArrayList<>();
                String prefLang = StorageSettings.getPreferredLanguage(this);

                for (EpisodeItem ep : episodes) {
                    try {
                        List<VideoSource> langs = api.getEpisodeLanguages(ep.id);
                        VideoSource selected = null;
                        for (VideoSource vs : langs) {
                            if (vs.language.equals(prefLang)) { selected = vs; break; }
                        }
                        if (selected == null && !langs.isEmpty()) selected = langs.get(0);
                        if (selected == null) continue;

                        String hlsUrl = api.resolveHlsFromEmbed(selected.url);
                        if (hlsUrl == null) continue;

                        ep.hlsUrl = hlsUrl;
                        ep.language = selected.language;
                        ep.langName = selected.quality;

                        DownloadManager.Job job = DownloadManager.enqueue(
                                animeTitle, "Episode " + ep.getLabel(),
                                StorageSettings.getPreferredQuality(this),
                                selected.language, hlsUrl
                        );
                        jobs.add(job);
                    } catch (Exception ignored) {}
                }

                if (!jobs.isEmpty()) {
                    Intent intent = DownloadService.startIntent(this, jobs);
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent);
                    } else {
                        startService(intent);
                    }
                    handler.post(() -> {
                        adapter.notifyDataSetChanged();
                        Toast.makeText(this, jobs.size() + " episodes queued", Toast.LENGTH_SHORT).show();
                    });
                }
            } catch (Exception e) {
                handler.post(() -> Toast.makeText(this, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show());
            }
        });
    }
}
