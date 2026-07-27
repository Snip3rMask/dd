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
    private RecyclerView downloadsList;
    private TextView emptyText;
    private DownloadAdapter downloadAdapter;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable refreshTask = new Runnable() {
        @Override
        public void run() {
            refresh();
            handler.postDelayed(this, 500);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_downloads);

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());
        findViewById(R.id.btn_clear_finished).setOnClickListener(v -> clearFinished());

        downloadsList = findViewById(R.id.downloads_list);
        emptyText = findViewById(R.id.empty_text);

        downloadAdapter = new DownloadAdapter(this, new DownloadAdapter.OnActionListener() {
            @Override public void onCancel(DownloadManager.Job job) {
                if (job != null) {
                    DownloadManager.cancel(job);
                    refresh();
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
                        android.widget.Toast.makeText(DownloadsActivity.this,
                                "Cannot open file", android.widget.Toast.LENGTH_SHORT).show();
                    }
                }
            }
            @Override public void onDelete(DownloadEntryStore.Entry entry) {
                DownloadEntry dlEntry = DownloadEntry.fromRecord(entry);
                showDeleteDownloadDialog(dlEntry);
            }
            @Override public void onSelectionToggle(DownloadEntryStore.Entry entry) {
                refresh();
            }
            @Override public boolean isSelected(DownloadEntryStore.Entry entry) {
                return false;
            }
            @Override public void onGroupDelete(String groupName) {
                downloadAdapter.toggleFolder(groupName);
                refresh();
            }
        });

        downloadsList.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        downloadsList.setAdapter(downloadAdapter);
    }

    @Override
    protected void onResume() {
        super.onResume();
        handler.post(refreshTask);
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

        emptyText.setVisibility(
            (!hasActive && (completed == null || completed.isEmpty())) ? View.VISIBLE : View.GONE);

        downloadAdapter.setData(active, completed);
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

    private void showDeleteDownloadDialog(DownloadEntry dlEntry) {
        android.widget.LinearLayout box = new android.widget.LinearLayout(this);
        box.setOrientation(android.widget.LinearLayout.VERTICAL);
        box.setPadding(dp(22), dp(22), dp(22), dp(22));

        android.widget.TextView title = new android.widget.TextView(this);
        title.setText("Delete " + dlEntry.title + "?");
        title.setTextColor(getColor(R.color.text_primary));
        title.setTextSize(18);
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        box.addView(title, new android.widget.LinearLayout.LayoutParams(-1, -2));

        android.widget.TextView message = new android.widget.TextView(this);
        message.setText("Remove from history keeps the file on your device. Delete file removes it permanently.");
        message.setTextColor(getColor(R.color.text_secondary));
        message.setTextSize(14);
        message.setLineSpacing(dp(3), 1f);
        android.widget.LinearLayout.LayoutParams msgLp = new android.widget.LinearLayout.LayoutParams(-1, -2);
        msgLp.setMargins(0, dp(8), 0, dp(22));
        box.addView(message, msgLp);

        AlertDialog dialog = new AlertDialog.Builder(this).setView(box).create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        }
        dialog.show();

        android.widget.TextView deleteBtn = new android.widget.TextView(this);
        deleteBtn.setText("Delete file");
        deleteBtn.setTextColor(getColor(R.color.on_primary));
        deleteBtn.setTextSize(15);
        deleteBtn.setTypeface(null, android.graphics.Typeface.BOLD);
        deleteBtn.setGravity(android.view.Gravity.CENTER);
        deleteBtn.setBackground(getDrawable(R.drawable.btn_primary));
        deleteBtn.setLayoutParams(new android.widget.LinearLayout.LayoutParams(-1, dp(50)));
        box.addView(deleteBtn);
        deleteBtn.setOnClickListener(v -> {
            dlEntry.deleteFileAndRecord(this);
            dialog.dismiss();
            refresh();
        });

        android.widget.TextView removeBtn = new android.widget.TextView(this);
        removeBtn.setText("Remove from history only");
        removeBtn.setTextColor(getColor(R.color.text_primary));
        removeBtn.setTextSize(14);
        removeBtn.setTypeface(null, android.graphics.Typeface.BOLD);
        removeBtn.setGravity(android.view.Gravity.CENTER);
        removeBtn.setBackground(UiHelper.rounded(getColor(R.color.surface_variant), dp(100)));
        android.widget.LinearLayout.LayoutParams remLp = new android.widget.LinearLayout.LayoutParams(-1, dp(50));
        remLp.setMargins(0, dp(10), 0, 0);
        box.addView(removeBtn, remLp);
        removeBtn.setOnClickListener(v -> {
            dlEntry.deleteRecordOnly(this);
            dialog.dismiss();
            refresh();
        });

        android.widget.TextView cancelBtn = new android.widget.TextView(this);
        cancelBtn.setText("Cancel");
        cancelBtn.setTextColor(getColor(R.color.text_tertiary));
        cancelBtn.setTextSize(14);
        cancelBtn.setTypeface(null, android.graphics.Typeface.BOLD);
        cancelBtn.setGravity(android.view.Gravity.CENTER);
        cancelBtn.setBackground(UiHelper.rounded(getColor(R.color.surface_variant), dp(100)));
        android.widget.LinearLayout.LayoutParams canLp = new android.widget.LinearLayout.LayoutParams(-1, dp(50));
        canLp.setMargins(0, dp(10), 0, 0);
        box.addView(cancelBtn, canLp);
        cancelBtn.setOnClickListener(v -> dialog.dismiss());
    }

    private int dp(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }
}
