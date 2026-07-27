package msr.mirudl.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.graphics.drawable.GradientDrawable;
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
    private final MiruClient client = MiruClient.getInstance();
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
                showFolderRequiredDialog();
                return;
            }
            showDownloadAllDialog();
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
                String title = client.getAnimeTitle(animeId);
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
                episodes = client.getEpisodes(animeId);
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
                List<VideoSource> langs = client.getEpisodeLanguages(ep.id);
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

                String hlsUrl = client.resolveHlsFromEmbed(selected.url);
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

    private void showFolderRequiredDialog() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(24), dp(24), dp(24), dp(20));

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);

        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.ic_folder);
        icon.setColorFilter(0xFF38BDF8);
        icon.setPadding(dp(8), dp(8), dp(8), dp(8));
        GradientDrawable iconBg = new GradientDrawable();
        iconBg.setShape(GradientDrawable.OVAL);
        iconBg.setColor(0x2238BDF8);
        icon.setBackground(iconBg);
        titleRow.addView(icon, new LinearLayout.LayoutParams(dp(44), dp(44)));

        TextView title = new TextView(this);
        title.setText("Download Folder Required");
        title.setTextColor(0xFFF1F0F7);
        title.setTextSize(16);
        title.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams tLp = new LinearLayout.LayoutParams(-1, -2);
        tLp.setMargins(dp(14), 0, 0, 0);
        titleRow.addView(title, tLp);
        box.addView(titleRow, new LinearLayout.LayoutParams(-1, -2));

        TextView msg = new TextView(this);
        msg.setText("Please select a download folder in Settings first.");
        msg.setTextColor(0xFF6B687C);
        msg.setTextSize(13);
        LinearLayout.LayoutParams msgLp = new LinearLayout.LayoutParams(-1, -2);
        msgLp.setMargins(0, dp(16), 0, dp(22));
        box.addView(msg, msgLp);

        // Settings button
        TextView settingsBtn = new TextView(this);
        settingsBtn.setText("Open Settings");
        settingsBtn.setTextColor(0xFFF1F0F7);
        settingsBtn.setTextSize(14);
        settingsBtn.setTypeface(null, Typeface.BOLD);
        settingsBtn.setGravity(Gravity.CENTER);
        GradientDrawable setBg = new GradientDrawable();
        setBg.setCornerRadius(dp(12));
        setBg.setColor(0xFF38BDF8);
        settingsBtn.setBackground(setBg);
        settingsBtn.setLayoutParams(new LinearLayout.LayoutParams(-1, dp(50)));
        box.addView(settingsBtn);
        settingsBtn.setOnClickListener(v -> {
            dialog.dismiss();
            startActivity(new Intent(DetailActivity.this, SettingsActivity.class));
        });

        // Cancel
        TextView cancelBtn = new TextView(this);
        cancelBtn.setText("Cancel");
        cancelBtn.setTextColor(0xFF6B687C);
        cancelBtn.setTextSize(13);
        cancelBtn.setTypeface(null, Typeface.BOLD);
        cancelBtn.setGravity(Gravity.CENTER);
        GradientDrawable canBg = new GradientDrawable();
        canBg.setCornerRadius(dp(12));
        canBg.setColor(0x00000000);
        canBg.setStroke(dp(1), 0xFF2E2F3D);
        cancelBtn.setBackground(canBg);
        LinearLayout.LayoutParams canLp = new LinearLayout.LayoutParams(-1, dp(48));
        canLp.setMargins(0, dp(10), 0, 0);
        box.addView(cancelBtn, canLp);
        cancelBtn.setOnClickListener(v -> dialog.dismiss());

        AlertDialog dialog = new AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            dialog.getWindow().setWindowAnimations(android.R.style.Animation_Dialog);
        }
        dialog.show();
    }

    private void showDownloadAllDialog() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(24), dp(24), dp(24), dp(20));

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);

        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.ic_download);
        icon.setColorFilter(0xFF38BDF8);
        icon.setPadding(dp(8), dp(8), dp(8), dp(8));
        GradientDrawable iconBg = new GradientDrawable();
        iconBg.setShape(GradientDrawable.OVAL);
        iconBg.setColor(0x2238BDF8);
        icon.setBackground(iconBg);
        titleRow.addView(icon, new LinearLayout.LayoutParams(dp(44), dp(44)));

        TextView title = new TextView(this);
        title.setText("Download All Episodes");
        title.setTextColor(0xFFF1F0F7);
        title.setTextSize(16);
        title.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams tLp = new LinearLayout.LayoutParams(-1, -2);
        tLp.setMargins(dp(14), 0, 0, 0);
        titleRow.addView(title, tLp);
        box.addView(titleRow, new LinearLayout.LayoutParams(-1, -2));

        TextView msg = new TextView(this);
        msg.setText("Start downloading all " + episodes.size() + " episodes?");
        msg.setTextColor(0xFF6B687C);
        msg.setTextSize(13);
        LinearLayout.LayoutParams msgLp = new LinearLayout.LayoutParams(-1, -2);
        msgLp.setMargins(0, dp(16), 0, dp(22));
        box.addView(msg, msgLp);

        // Download All button
        TextView downloadBtn = new TextView(this);
        downloadBtn.setText("Download All (" + episodes.size() + ")");
        downloadBtn.setTextColor(0xFFF1F0F7);
        downloadBtn.setTextSize(14);
        downloadBtn.setTypeface(null, Typeface.BOLD);
        downloadBtn.setGravity(Gravity.CENTER);
        GradientDrawable dlBg = new GradientDrawable();
        dlBg.setCornerRadius(dp(12));
        dlBg.setColor(0xFF38BDF8);
        downloadBtn.setBackground(dlBg);
        downloadBtn.setLayoutParams(new LinearLayout.LayoutParams(-1, dp(50)));
        box.addView(downloadBtn);
        downloadBtn.setOnClickListener(v -> {
            dialog.dismiss();
            downloadAllEpisodes();
        });

        // Cancel
        TextView cancelBtn = new TextView(this);
        cancelBtn.setText("Cancel");
        cancelBtn.setTextColor(0xFF6B687C);
        cancelBtn.setTextSize(13);
        cancelBtn.setTypeface(null, Typeface.BOLD);
        cancelBtn.setGravity(Gravity.CENTER);
        GradientDrawable canBg = new GradientDrawable();
        canBg.setCornerRadius(dp(12));
        canBg.setColor(0x00000000);
        canBg.setStroke(dp(1), 0xFF2E2F3D);
        cancelBtn.setBackground(canBg);
        LinearLayout.LayoutParams canLp = new LinearLayout.LayoutParams(-1, dp(48));
        canLp.setMargins(0, dp(10), 0, 0);
        box.addView(cancelBtn, canLp);
        cancelBtn.setOnClickListener(v -> dialog.dismiss());

        AlertDialog dialog = new AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            dialog.getWindow().setWindowAnimations(android.R.style.Animation_Dialog);
        }
        dialog.show();
    }

    private void startDownload(EpisodeItem ep) {
        if (!StorageSettings.hasDownloadUri(this)) {
            showFolderRequiredDialog();
            return;
        }


        String quality = StorageSettings.getPreferredQuality(this);
        String language = ep.language != null ? ep.language : "jpn";
        String hlsUrl = ep.hlsUrl;

        executor.execute(() -> {
            try {
                List<VideoSource> variants = client.getQualities(hlsUrl);
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
        // Guard: skip if already queued or downloading
        String label = "Episode " + ep.getLabel();
        for (DownloadManager.Job existing : DownloadManager.snapshot()) {
            if (!existing.finished && existing.animeTitle.equals(animeTitle) && existing.episodeTitle.equals(label)) {
                handler.post(() -> Toast.makeText(this, "Already queued: " + label, Toast.LENGTH_SHORT).show());
                return;
            }
        }

        DownloadManager.Job job = DownloadManager.enqueue(
                animeTitle, label, quality, language, hlsUrl
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

        handler.post(() -> Toast.makeText(this, "Queued: " + label, Toast.LENGTH_SHORT).show());
    }

    private void downloadAllEpisodes() {
        executor.execute(() -> {
            try {
                List<DownloadManager.Job> jobs = new ArrayList<>();
                String prefLang = StorageSettings.getPreferredLanguage(this);

                for (EpisodeItem ep : episodes) {
                    try {
                        List<VideoSource> langs = client.getEpisodeLanguages(ep.id);
                        VideoSource selected = null;
                        for (VideoSource vs : langs) {
                            if (vs.language.equals(prefLang)) { selected = vs; break; }
                        }
                        if (selected == null && !langs.isEmpty()) selected = langs.get(0);
                        if (selected == null) continue;

                        String hlsUrl = client.resolveHlsFromEmbed(selected.url);
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
