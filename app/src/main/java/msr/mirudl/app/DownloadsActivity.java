package msr.mirudl.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public class DownloadsActivity extends BaseActivity {
    private RecyclerView activeList, completedList;
    private View activeSection, completedSection;
    private TextView emptyText;
    private DownloadAdapter activeAdapter, completedAdapter;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable refreshTask = this::refresh;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_downloads);

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());
        findViewById(R.id.btn_clear_finished).setOnClickListener(v -> clearFinished());

        activeList = findViewById(R.id.active_downloads);
        completedList = findViewById(R.id.completed_downloads);
        activeSection = findViewById(R.id.active_section);
        completedSection = findViewById(R.id.completed_section);
        emptyText = findViewById(R.id.empty_text);

        activeAdapter = new DownloadAdapter(this, true, null, new DownloadAdapter.OnActionListener() {
            @Override public void onCancel(DownloadManager.Job job) {
                if (job != null) {
                    DownloadManager.cancel(job);
                    refresh();
                }
            }
            @Override public void onClick(DownloadEntryStore.Entry entry) {}
            @Override public void onDelete(DownloadEntryStore.Entry entry) {
                DownloadEntryStore.remove(DownloadsActivity.this, entry);
                refresh();
            }
        });

        completedAdapter = new DownloadAdapter(this, false, null, new DownloadAdapter.OnActionListener() {
            @Override public void onCancel(DownloadManager.Job job) {}
            @Override public void onClick(DownloadEntryStore.Entry entry) {
                // Open file
                if (entry != null && entry.uri != null && !entry.uri.isEmpty()) {
                    try {
                        android.net.Uri fileUri = android.net.Uri.parse(entry.uri);
                        Intent intent = new Intent(Intent.ACTION_VIEW);
                        intent.setDataAndType(fileUri, "video/mp4");
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        startActivity(intent);
                    } catch (Exception e) {
                        android.widget.Toast.makeText(DownloadsActivity.this,
                                "Cannot open file", android.widget.Toast.LENGTH_SHORT).show();
                    }
                }
            }
            @Override public void onDelete(DownloadEntryStore.Entry entry) {
                DownloadEntryStore.remove(DownloadsActivity.this, entry);
                refresh();
            }
        });

        activeList.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        completedList.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        activeList.setAdapter(activeAdapter);
        completedList.setAdapter(completedAdapter);
    }

    @Override
    protected void onResume() {
        super.onResume();
        refresh();
        handler.postDelayed(refreshTask, 2000);
    }

    @Override
    protected void onPause() {
        super.onPause();
        handler.removeCallbacks(refreshTask);
    }

    private void refresh() {
        List<DownloadManager.Job> active = DownloadManager.snapshot();
        List<DownloadEntryStore.Entry> completed = DownloadEntryStore.all(this);

        boolean hasActive = false;
        for (DownloadManager.Job j : active) {
            if (!j.finished) { hasActive = true; break; }
        }

        activeSection.setVisibility(hasActive ? View.VISIBLE : View.GONE);
        completedSection.setVisibility(!completed.isEmpty() ? View.VISIBLE : View.GONE);
        emptyText.setVisibility(!hasActive && completed.isEmpty() ? View.VISIBLE : View.GONE);

        activeAdapter.setJobs(active);
        completedAdapter.setEntries(completed);
    }

    private void clearFinished() {
        List<DownloadEntryStore.Entry> entries = DownloadEntryStore.all(this);
        if (!entries.isEmpty()) {
            new AlertDialog.Builder(this)
                    .setTitle("Clear History")
                    .setMessage("Remove all download history?")
                    .setPositiveButton("Clear", (d, w) -> {
                        DownloadEntryStore.removeAll(this, entries);
                        refresh();
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
        }
        DownloadManager.removeFinished();
        refresh();
    }
}
