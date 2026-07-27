package msr.mirudl.app;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import org.json.JSONObject;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import android.widget.ScrollView;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import android.graphics.Typeface;
import android.view.Gravity;
import android.widget.LinearLayout;
import java.util.HashSet;
import java.util.Set;

public class MainActivity extends BaseActivity {
    // Tabs
    private View tabHome, tabDownloads, tabSettings;
    private BottomNavigationView bottomNav;

    // Home
    private EditText searchInput;
    private RecyclerView animeGrid;
    private ProgressBar loadingBar;
    private TextView emptyText;
    private AnimeGridAdapter gridAdapter;
    private final MiruClient client = MiruClient.getInstance();

    // Downloads
    private RecyclerView downloadsList;
    private TextView emptyTextDl, btnClearFinished;
    private DownloadAdapter downloadAdapter;

    private final Set<String> selectedDownloadKeys = new HashSet<>();
    // Settings
    private TextView folderText;
    private SeekBar parallelBar;
    private TextView parallelValue;
    private Spinner qualitySpinner, langSpinner;

    // Common
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable refreshTask = new Runnable() {
        @Override
        public void run() {
            refreshDownloads();
            handler.postDelayed(this, 500);
        }
    };

    // Folder picker
    private final ActivityResultLauncher<Intent> folderPicker =
            registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
                if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                    Uri treeUri = result.getData().getData();
                    if (treeUri != null) {
                        try {
                            getContentResolver().takePersistableUriPermission(
                                    treeUri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION |
                                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            );
                        } catch (Exception ignored) {}
                        StorageSettings.setDownloadUri(this, treeUri);
                        updateFolderDisplay();
                        Toast.makeText(this, "Download folder set", Toast.LENGTH_SHORT).show();
                    }
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        try {
            onCreateInternal(savedInstanceState);
        } catch (Exception e) {
            new android.app.AlertDialog.Builder(this)
                    .setTitle("Startup Error")
                    .setMessage(e.getClass().getSimpleName() + ": " + e.getMessage())
                    .setPositiveButton("Exit", (d, w) -> finish())
                    .setCancelable(false)
                    .show();
            CrashLogger.saveCaughtException(this, Thread.currentThread(), e);
        }
    }

    private void onCreateInternal(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Find tabs
        tabHome = findViewById(R.id.tab_home);
        tabDownloads = findViewById(R.id.tab_downloads);
        tabSettings = findViewById(R.id.tab_settings);

        // Bottom nav
        bottomNav = findViewById(R.id.bottom_nav);
        bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_home) {
                showTab(0);
                return true;
            } else if (id == R.id.nav_downloads) {
                showTab(1);
                return true;
            } else if (id == R.id.nav_settings) {
                showTab(2);
                return true;
            }
            return false;
        });

        // Init Home tab
        initHomeTab();

        // Init Downloads tab
        initDownloadsTab();

        // Init Settings tab
        initSettingsTab();

        // Start on Home
        showTab(0);
        loadPopular();
    }

    // ============ TAB SWITCHING ============

    private void showTab(int tab) {
        tabHome.setVisibility(tab == 0 ? View.VISIBLE : View.GONE);
        tabDownloads.setVisibility(tab == 1 ? View.VISIBLE : View.GONE);
        tabSettings.setVisibility(tab == 2 ? View.VISIBLE : View.GONE);

        if (tab == 1) refreshDownloads();
        if (tab == 2) updateFolderDisplay();
    }

    // ============ HOME TAB ============

    private void initHomeTab() {
        searchInput = findViewById(R.id.search_input);
        animeGrid = findViewById(R.id.anime_grid);
        loadingBar = findViewById(R.id.loading_bar);
        emptyText = findViewById(R.id.empty_text);

        gridAdapter = new AnimeGridAdapter(anime -> {
            // Show detail bottom sheet
            showAnimeDetail(anime);
        });

        animeGrid.setLayoutManager(new GridLayoutManager(this, 2));
        animeGrid.setAdapter(gridAdapter);

        searchInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void afterTextChanged(Editable s) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (s.length() >= 2) {
                    searchAnime(s.toString());
                } else if (s.length() == 0) {
                    loadPopular();
                }
            }
        });

        searchInput.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH && v.getText().length() >= 2) {
                searchAnime(v.getText().toString());
                return true;
            }
            return false;
        });
    }

    private void loadPopular() {
        loadingBar.setVisibility(View.VISIBLE);
        emptyText.setVisibility(View.GONE);
        executor.execute(() -> {
            try {
                List<AnimeItem> results = client.browseCurrentlyAiring();
                handler.post(() -> {
                    loadingBar.setVisibility(View.GONE);
                    if (results != null && !results.isEmpty()) {
                        gridAdapter.setItems(results);
                    } else {
                        emptyText.setText(R.string.no_results);
                        emptyText.setVisibility(View.VISIBLE);
                    }
                });
            } catch (Exception e) {
                handler.post(() -> {
                    loadingBar.setVisibility(View.GONE);
                    emptyText.setText("Error loading");
                    emptyText.setVisibility(View.VISIBLE);
                });
            }
        });
    }

    private void searchAnime(String query) {
        loadingBar.setVisibility(View.VISIBLE);
        emptyText.setVisibility(View.GONE);
        executor.execute(() -> {
            try {
                List<AnimeItem> results = client.search(query);
                handler.post(() -> {
                    loadingBar.setVisibility(View.GONE);
                    gridAdapter.setItems(results);
                    if (results.isEmpty()) {
                        emptyText.setText(R.string.no_results);
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

    private void showAnimeDetail(AnimeItem anime) {
        // Inflate bottom sheet
        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this, android.R.style.Theme_Translucent_NoTitleBar)
                .setView(R.layout.bottom_sheet_detail)
                .create();

        dialog.show();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            dialog.getWindow().setLayout(
                    android.view.WindowManager.LayoutParams.MATCH_PARENT,
                    android.view.WindowManager.LayoutParams.WRAP_CONTENT
            );
            dialog.getWindow().setGravity(android.view.Gravity.BOTTOM);
        }

        View view = dialog.getWindow() != null ? dialog.getWindow().getDecorView().findViewById(android.R.id.content) : null;
        if (view == null) {
            dialog.dismiss();
            // Fallback: open DetailActivity
            Intent intent = new Intent(this, DetailActivity.class);
            intent.putExtra("anime_id", anime.id);
            intent.putExtra("anime_title", anime.title);
            intent.putExtra("anime_thumb", anime.thumbnail);
            startActivity(intent);
            return;
        }

        ImageView thumb = view.findViewById(R.id.detail_thumb);
        TextView title = view.findViewById(R.id.detail_title);
        TextView info = view.findViewById(R.id.detail_info);
        TextView desc = view.findViewById(R.id.detail_description);
        TextView btnEpisodes = view.findViewById(R.id.btn_view_episodes);

        if (anime.thumbnail != null && !anime.thumbnail.isEmpty()) {
            com.bumptech.glide.Glide.with(this).load(anime.thumbnail).centerCrop().into(thumb);
        }
        title.setText(anime.title != null ? anime.title : "Unknown");

        // Fetch anime title
        executor.execute(() -> {
            try {
                String remoteTitle = client.getAnimeTitle(anime.id);
                if (remoteTitle != null && !remoteTitle.isEmpty()) {
                    String finalTitle = remoteTitle;
                    handler.post(() -> title.setText(finalTitle));
                }
            } catch (Exception ignored) {}
        });

        btnEpisodes.setOnClickListener(v -> {
            dialog.dismiss();
            Intent intent = new Intent(this, DetailActivity.class);
            intent.putExtra("anime_id", anime.id);
            intent.putExtra("anime_title", anime.title);
            intent.putExtra("anime_thumb", anime.thumbnail);
            startActivity(intent);
        });
    }

    // ============ DOWNLOADS TAB ============

    private void initDownloadsTab() {
        downloadsList = findViewById(R.id.downloads_list);
        emptyTextDl = findViewById(R.id.empty_text_dl);
        btnClearFinished = findViewById(R.id.btn_clear_finished);

        btnClearFinished.setOnClickListener(v -> clearFinished());

        downloadAdapter = new DownloadAdapter(this, new DownloadAdapter.OnActionListener() {
            @Override public void onCancel(DownloadManager.Job job) {
                if (job != null) {
                    DownloadManager.cancel(job);
                    // Also notify the service
                    Intent cancelIntent = new Intent(MainActivity.this, DownloadService.class);
                    cancelIntent.setAction("cancel");
                    cancelIntent.putExtra("jobId", job.id);
                    startService(cancelIntent);
                    refreshDownloads();
                }
            }
            @Override public void onClick(DownloadEntryStore.Entry entry) {
                DownloadEntry dlEntry = DownloadEntry.fromRecord(entry);
                if (dlEntry.uri != null) {
                    try {
                        Intent intent = new Intent(Intent.ACTION_VIEW);
                        intent.setDataAndType(dlEntry.uri, "video/mp4");
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        startActivity(intent);
                    } catch (Exception e) {
                        Toast.makeText(MainActivity.this, "Cannot open file", Toast.LENGTH_SHORT).show();
                    }
                }
            }
            @Override public void onDelete(DownloadEntryStore.Entry entry) {
                DownloadEntry dlEntry = DownloadEntry.fromRecord(entry);
                showDeleteDownloadDialog(dlEntry);
            }
            @Override public void onSelectionToggle(DownloadEntryStore.Entry entry) {
                DownloadEntry dlEntry = DownloadEntry.fromRecord(entry);
                String key = dlEntry.key();
                if (selectedDownloadKeys.contains(key)) {
                    selectedDownloadKeys.remove(key);
                } else {
                    selectedDownloadKeys.add(key);
                }
                refreshDownloads();
            }
            @Override public boolean isSelected(DownloadEntryStore.Entry entry) {
                DownloadEntry dlEntry = DownloadEntry.fromRecord(entry);
                return selectedDownloadKeys.contains(dlEntry.key());
            }
            @Override public void onGroupDeleteRequest(String groupName) {
                List<DownloadEntry> groupEntries = new ArrayList<>();
                List<DownloadEntryStore.Entry> all = DownloadEntryStore.all(MainActivity.this);
                for (DownloadEntryStore.Entry e : all) {
                    if (groupName.equals(e.parentName())) {
                        groupEntries.add(DownloadEntry.fromRecord(e));
                    }
                }
                showDeleteMultipleDialog(groupEntries);
            }

            @Override public void onGroupDelete(String groupName) {
                // Toggle folder expansion
                downloadAdapter.toggleFolder(groupName);
                refreshDownloads();
            }
        });

        downloadsList.setLayoutManager(new LinearLayoutManager(this));
        downloadsList.setAdapter(downloadAdapter);
    }

    private void refreshDownloads() {
        List<DownloadManager.Job> active = DownloadManager.snapshot();
        List<DownloadEntryStore.Entry> completed = DownloadEntryStore.all(this);

        boolean hasActive = false;
        for (DownloadManager.Job j : active) {
            if (!j.finished) { hasActive = true; break; }
        }

        emptyTextDl.setVisibility(
            (!hasActive && (completed == null || completed.isEmpty())) ? View.VISIBLE : View.GONE);

        downloadAdapter.setData(active, completed);
    }

    private void clearFinished() {
        DownloadManager.removeFinished();
        List<DownloadEntryStore.Entry> entries = DownloadEntryStore.all(this);
        if (!entries.isEmpty()) {
            new android.app.AlertDialog.Builder(this)
                    .setTitle("Clear History")
                    .setMessage("Remove all download history?")
                    .setPositiveButton("Clear", (d, w) -> {
                        DownloadEntryStore.removeAll(this, entries);
                        refreshDownloads();
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
        }
        refreshDownloads();
    }

    private void showDeleteDownloadDialog(DownloadEntry dlEntry) {
        int bgColor = 0xFF1A1B23;
        int radius = dp(20);
        int accentColor = 0xFF38BDF8;
        int errorColor = 0xFFF87171;

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(24), dp(24), dp(24), dp(20));

        // Icon + Title row
        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);

        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.ic_delete);
        icon.setColorFilter(errorColor);
        icon.setPadding(dp(8), dp(8), dp(8), dp(8));
        GradientDrawable iconBg = new GradientDrawable();
        iconBg.setShape(GradientDrawable.OVAL);
        iconBg.setColor(0x22F87171);
        icon.setBackground(iconBg);
        titleRow.addView(icon, new LinearLayout.LayoutParams(dp(44), dp(44)));

        TextView title = new TextView(this);
        title.setText("Delete download?");
        title.setTextColor(0xFFF1F0F7);
        title.setTextSize(17);
        title.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams tLp = new LinearLayout.LayoutParams(-1, -2);
        tLp.setMargins(dp(14), 0, 0, 0);
        titleRow.addView(title, tLp);
        box.addView(titleRow, new LinearLayout.LayoutParams(-1, -2));

        // Episode name
        TextView epName = new TextView(this);
        String displayName = dlEntry.title != null ? dlEntry.title : "";
        if (displayName.startsWith("Episode ")) displayName = displayName.substring(8);
        epName.setText(displayName);
        epName.setTextColor(0xFF6B687C);
        epName.setTextSize(13);
        epName.setMaxLines(2);
        epName.setEllipsize(android.text.TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams enLp = new LinearLayout.LayoutParams(-1, -2);
        enLp.setMargins(dp(58), dp(4), 0, dp(20));
        box.addView(epName, enLp);

        // Action buttons
        TextView deleteBtn = new TextView(this);
        deleteBtn.setText("Delete file permanently");
        deleteBtn.setTextColor(0xFFF1F0F7);
        deleteBtn.setTextSize(14);
        deleteBtn.setTypeface(null, Typeface.BOLD);
        deleteBtn.setGravity(Gravity.CENTER);
        deleteBtn.setPadding(0, 0, 0, 0);
        GradientDrawable delBg = new GradientDrawable();
        delBg.setCornerRadius(dp(12));
        delBg.setColor(errorColor);
        deleteBtn.setBackground(delBg);
        deleteBtn.setLayoutParams(new LinearLayout.LayoutParams(-1, dp(50)));
        box.addView(deleteBtn);
        deleteBtn.setOnClickListener(v -> {
            dlEntry.deleteFileAndRecord(this);
            dialog.dismiss();
            refreshDownloads();
        });

        TextView removeBtn = new TextView(this);
        removeBtn.setText("Remove from history only");
        removeBtn.setTextColor(0xFFF1F0F7);
        removeBtn.setTextSize(13);
        removeBtn.setTypeface(null, Typeface.BOLD);
        removeBtn.setGravity(Gravity.CENTER);
        GradientDrawable remBg = new GradientDrawable();
        remBg.setCornerRadius(dp(12));
        remBg.setColor(0xFF22232D);
        removeBtn.setBackground(remBg);
        LinearLayout.LayoutParams remLp = new LinearLayout.LayoutParams(-1, dp(48));
        remLp.setMargins(0, dp(10), 0, 0);
        box.addView(removeBtn, remLp);
        removeBtn.setOnClickListener(v -> {
            dlEntry.deleteRecordOnly(this);
            dialog.dismiss();
            refreshDownloads();
        });

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

        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            dialog.getWindow().setWindowAnimations(android.R.style.Animation_Dialog);
        }
        dialog.show();
    }

    private void showDeleteMultipleDialog(List<DownloadEntry> entries) {
        if (entries.isEmpty()) return;
        String desc = entries.size() == 1 ? entries.get(0).title : entries.size() + " files";
        int errorColor = 0xFFF87171;

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(24), dp(24), dp(24), dp(20));

        // Icon + Title row
        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);

        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.ic_delete);
        icon.setColorFilter(errorColor);
        icon.setPadding(dp(8), dp(8), dp(8), dp(8));
        GradientDrawable iconBg = new GradientDrawable();
        iconBg.setShape(GradientDrawable.OVAL);
        iconBg.setColor(0x22F87171);
        icon.setBackground(iconBg);
        titleRow.addView(icon, new LinearLayout.LayoutParams(dp(44), dp(44)));

        TextView title = new TextView(this);
        title.setText("Delete " + desc + "?");
        title.setTextColor(0xFFF1F0F7);
        title.setTextSize(17);
        title.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams tLp = new LinearLayout.LayoutParams(-1, -2);
        tLp.setMargins(dp(14), 0, 0, 0);
        titleRow.addView(title, tLp);
        box.addView(titleRow, new LinearLayout.LayoutParams(-1, -2));

        TextView message = new TextView(this);
        message.setText("Removing from history keeps the file on your device.");
        message.setTextColor(0xFF6B687C);
        message.setTextSize(13);
        LinearLayout.LayoutParams msgLp = new LinearLayout.LayoutParams(-1, -2);
        msgLp.setMargins(dp(58), dp(4), 0, dp(20));
        box.addView(message, msgLp);

        // Delete files button
        TextView deleteBtn = new TextView(this);
        deleteBtn.setText("Delete files permanently");
        deleteBtn.setTextColor(0xFFF1F0F7);
        deleteBtn.setTextSize(14);
        deleteBtn.setTypeface(null, Typeface.BOLD);
        deleteBtn.setGravity(Gravity.CENTER);
        GradientDrawable delBg = new GradientDrawable();
        delBg.setCornerRadius(dp(12));
        delBg.setColor(errorColor);
        deleteBtn.setBackground(delBg);
        deleteBtn.setLayoutParams(new LinearLayout.LayoutParams(-1, dp(50)));
        box.addView(deleteBtn);
        deleteBtn.setOnClickListener(v -> {
            for (DownloadEntry e : entries) e.deleteFileAndRecord(this);
            selectedDownloadKeys.clear();
            dialog.dismiss();
            refreshDownloads();
        });

        // Remove from history
        TextView removeBtn = new TextView(this);
        removeBtn.setText("Remove from history only");
        removeBtn.setTextColor(0xFFF1F0F7);
        removeBtn.setTextSize(13);
        removeBtn.setTypeface(null, Typeface.BOLD);
        removeBtn.setGravity(Gravity.CENTER);
        GradientDrawable remBg = new GradientDrawable();
        remBg.setCornerRadius(dp(12));
        remBg.setColor(0xFF22232D);
        removeBtn.setBackground(remBg);
        LinearLayout.LayoutParams remLp = new LinearLayout.LayoutParams(-1, dp(48));
        remLp.setMargins(0, dp(10), 0, 0);
        box.addView(removeBtn, remLp);
        removeBtn.setOnClickListener(v -> {
            for (DownloadEntry e : entries) e.deleteRecordOnly(this);
            selectedDownloadKeys.clear();
            dialog.dismiss();
            refreshDownloads();
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

        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
            dialog.getWindow().setWindowAnimations(android.R.style.Animation_Dialog);
        }
        dialog.show();
    }

    // ============ SETTINGS TAB ============

    private void showCrashLogsDialog() {
        CrashLogger.markViewed(this);
        File[] files = CrashLogger.getCrashFiles(this);

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(22), dp(22), dp(22), dp(22));

        TextView title = new TextView(this);
        title.setText("Crash Reports (" + files.length + ")");
        title.setTextColor(getColor(R.color.text_primary));
        title.setTextSize(18);
        title.setTypeface(null, Typeface.BOLD);
        box.addView(title, new LinearLayout.LayoutParams(-1, -2));

        if (files.length == 0) {
            TextView empty = new TextView(this);
            empty.setText("No crash logs");
            empty.setTextColor(getColor(R.color.text_tertiary));
            empty.setTextSize(14);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(0, dp(32), 0, dp(32));
            box.addView(empty, new LinearLayout.LayoutParams(-1, -2));
        } else {
            // Clear All button
            TextView clearAll = new TextView(this);
            clearAll.setText("Clear All");
            clearAll.setTextColor(getColor(R.color.primary));
            clearAll.setTextSize(13);
            clearAll.setTypeface(null, Typeface.BOLD);
            clearAll.setGravity(Gravity.END);
            clearAll.setPadding(0, dp(8), 0, dp(12));
            clearAll.setOnClickListener(v -> {
                CrashLogger.clearAll(this);
                showCrashLogsDialog();
            });
            box.addView(clearAll, new LinearLayout.LayoutParams(-1, -2));

            // List crash files
            for (File file : files) {
                LinearLayout row = new LinearLayout(this);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.CENTER_VERTICAL);
                row.setPadding(dp(4), dp(8), dp(4), dp(8));
                row.setBackground(UiHelper.rounded(getColor(R.color.surface_variant), dp(12)));
                LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(-1, -2);
                rowLp.setMargins(0, 0, 0, dp(6));
                row.setLayoutParams(rowLp);

                String dateStr = new SimpleDateFormat("MMM dd, hh:mm a", Locale.US)
                        .format(new Date(file.lastModified()));
                long sizeKb = file.length() / 1024;

                TextView info = new TextView(this);
                info.setText(dateStr + "  \u2022  " + (sizeKb > 0 ? sizeKb + " KB" : "<1 KB"));
                info.setTextColor(getColor(R.color.text_primary));
                info.setTextSize(12);
                info.setLayoutParams(new LinearLayout.LayoutParams(0, -2, 1));
                row.addView(info);

                // Delete button
                TextView delBtn = new TextView(this);
                delBtn.setText("Delete");
                delBtn.setTextColor(getColor(R.color.error));
                delBtn.setTextSize(12);
                delBtn.setPadding(dp(8), dp(4), dp(8), dp(4));
                delBtn.setOnClickListener(v -> {
                    CrashLogger.deleteCrashFile(file);
                    showCrashLogsDialog();
                });
                row.addView(delBtn);

                // View button
                TextView viewBtn = new TextView(this);
                viewBtn.setText("View");
                viewBtn.setTextColor(getColor(R.color.primary));
                viewBtn.setTextSize(12);
                viewBtn.setPadding(dp(8), dp(4), dp(8), dp(4));
                viewBtn.setOnClickListener(v -> showCrashDetailDialog(file));
                row.addView(viewBtn);

                box.addView(row);
            }
        }

        // Close button
        TextView closeBtn = new TextView(this);
        closeBtn.setText("Close");
        closeBtn.setTextColor(0xFF6B687C);
        closeBtn.setTextSize(14);
        closeBtn.setTypeface(null, Typeface.BOLD);
        closeBtn.setGravity(Gravity.CENTER);
        GradientDrawable closeBg = new GradientDrawable();
        closeBg.setCornerRadius(dp(12));
        closeBg.setColor(0x00000000);
        closeBg.setStroke(dp(1), 0xFF2E2F3D);
        closeBtn.setBackground(closeBg);
        closeBtn.setPadding(0, 0, 0, 0);
        LinearLayout.LayoutParams closeLp = new LinearLayout.LayoutParams(-1, dp(48));
        closeLp.setMargins(0, dp(12), 0, 0);
        closeBtn.setLayoutParams(closeLp);
        closeBtn.setGravity(Gravity.CENTER);
        closeBtn.setBackground(UiHelper.rounded(getColor(R.color.surface_variant), dp(100)));
        LinearLayout.LayoutParams closeLp = new LinearLayout.LayoutParams(-1, dp(50));
        closeLp.setMargins(0, dp(12), 0, 0);
        box.addView(closeBtn, closeLp);

        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null)
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        dialog.show();
        closeBtn.setOnClickListener(v -> dialog.dismiss());
    }

    private void showCrashDetailDialog(File file) {
        StringBuilder content = new StringBuilder();
        try {
            java.io.BufferedReader r = new java.io.BufferedReader(new java.io.FileReader(file));
            String line;
            while ((line = r.readLine()) != null) {
                if (content.length() > 5000) {
                    content.append("\n... [TRUNCATED - file too large]");
                    break;
                }
                content.append(line).append("\n");
            }
            r.close();
        } catch (Exception ignored) {}

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(16), dp(16), dp(16), dp(16));

        TextView title = new TextView(this);
        title.setText("Crash Log");
        title.setTextColor(getColor(R.color.text_primary));
        title.setTextSize(16);
        title.setTypeface(null, Typeface.BOLD);
        box.addView(title, new LinearLayout.LayoutParams(-1, -2));

        ScrollView scroll = new ScrollView(this);
        TextView logText = new TextView(this);
        logText.setText(content.toString());
        logText.setTextColor(getColor(R.color.text_secondary));
        logText.setTextSize(10);
        logText.setTypeface(Typeface.MONOSPACE);
        logText.setLineSpacing(dp(2), 1f);
        scroll.addView(logText);
        LinearLayout.LayoutParams scrollLp = new LinearLayout.LayoutParams(-1, dp(400));
        scrollLp.setMargins(0, dp(12), 0, dp(12));
        box.addView(scroll, scrollLp);

        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null)
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        dialog.show();
    }


    private String speedLabel(int parallel) {
        if (parallel <= 4) return "Slow";
        if (parallel <= 8) return "Normal";
        if (parallel <= 16) return "Fast";
        return "Very Fast";
    }

    private void initSettingsTab() {
        folderText = findViewById(R.id.folder_path);
        findViewById(R.id.btn_select_folder).setOnClickListener(v -> pickFolder());

        parallelBar = findViewById(R.id.parallel_seekbar);
        parallelValue = findViewById(R.id.parallel_value);

        int currentParallel = StorageSettings.getParallelSegments(this);
        parallelBar.setProgress(currentParallel);
        parallelValue.setText(String.valueOf(currentParallel));

        parallelBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onStartTrackingTouch(SeekBar bar) {}
            @Override public void onStopTrackingTouch(SeekBar bar) {}
            @Override
            public void onProgressChanged(SeekBar bar, int progress, boolean fromUser) {
                if (fromUser) {
                    int val = Math.max(1, progress);
                    parallelValue.setText(String.valueOf(val));
                    StorageSettings.setParallelSegments(MainActivity.this, val);
                }
            }
        });

        qualitySpinner = findViewById(R.id.quality_spinner);
        String[] qualities = {"1080p", "720p", "480p", "360p", "Auto"};
        ArrayAdapter<String> qAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_dropdown_item, qualities);
        qualitySpinner.setAdapter(qAdapter);
        String prefQ = StorageSettings.getPreferredQuality(this);
        for (int i = 0; i < qualities.length; i++) {
            if (qualities[i].equals(prefQ)) { qualitySpinner.setSelection(i); break; }
        }
        qualitySpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override public void onItemSelected(AdapterView<?> p, View v, int pos, long id) {
                StorageSettings.setPreferredQuality(MainActivity.this, qualities[pos]);
            }
            @Override public void onNothingSelected(AdapterView<?> p) {}
        });

        langSpinner = findViewById(R.id.lang_spinner);
        String[] langs = {"jpn", "eng"};
        String[] langLabels = {"Sub (Japanese)", "Dub (English)"};
        ArrayAdapter<String> lAdapter = new ArrayAdapter<>(this,
                android.R.layout.simple_spinner_dropdown_item, langLabels);
        langSpinner.setAdapter(lAdapter);
        String prefLang = StorageSettings.getPreferredLanguage(this);
        for (int i = 0; i < langs.length; i++) {
            if (langs[i].equals(prefLang)) { langSpinner.setSelection(i); break; }
        }
        langSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override public void onItemSelected(AdapterView<?> p, View v, int pos, long id) {
                StorageSettings.setPreferredLanguage(MainActivity.this, langs[pos]);
            }
            @Override public void onNothingSelected(AdapterView<?> p) {}
        });

        // GitHub link in Developer section
        View githubLink = findViewById(R.id.id_github_link);
        if (githubLink != null) {
            githubLink.setOnClickListener(v -> {
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW,
                            Uri.parse("https://github.com/msrofficial/MiruDL-App")));
                } catch (Exception ignored) {}
            });
        }

        // Crash Reports button
        View crashBtn = findViewById(R.id.btn_crash_reports);
        if (crashBtn != null) {
            crashBtn.setOnClickListener(v -> showCrashLogsDialog());
        }

        // About section - app card click (if any future use)
        View appSection = findViewById(R.id.btn_crash_reports);
        // Already handled above

        updateFolderDisplay();
    }

    private void pickFolder() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION |
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION |
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        folderPicker.launch(intent);
    }

    private void updateFolderDisplay() {
        Uri uri = StorageSettings.getDownloadUri(this);
        if (uri != null) {
            String path = uri.getPath();
            String display = path != null && path.contains(":")
                    ? path.substring(path.indexOf(":") + 1) : path;
            folderText.setText(display != null ? display : uri.toString());
        } else {
            folderText.setText("Not selected");
        }
    }

    // ============ LIFECYCLE ============

    @Override
    protected void onResume() {
        super.onResume();
        handler.post(refreshTask);
    }

    private int dp(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }

    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(refreshTask);
    }
}
