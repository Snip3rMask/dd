package msr.mirudl.app;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class DownloadAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private final Context context;
    private final boolean showActive;
    private List<DownloadManager.Job> jobs = new ArrayList<>();
    private List<DownloadEntryStore.Entry> entries = new ArrayList<>();
    private final OnActionListener listener;

    public interface OnActionListener {
        default void onCancel(DownloadManager.Job job) {}
        default void onClick(DownloadEntryStore.Entry entry) {}
        default void onDelete(DownloadEntryStore.Entry entry) {}
        default void onSelectionToggle(DownloadEntryStore.Entry entry) {}
        default boolean isSelected(DownloadEntryStore.Entry entry) { return false; }
        default void onGroupDelete(String groupName) {}
    }

    public DownloadAdapter(Context context, boolean showActive,
                           DownloadManager.Job activeJob,
                           OnActionListener listener) {
        this.context = context;
        this.showActive = showActive;
        this.listener = listener;
        if (activeJob != null && showActive) {
            this.jobs.add(activeJob);
        }
    }

    public void setJobs(List<DownloadManager.Job> jobs) {
        this.jobs = jobs != null ? jobs : new ArrayList<>();
        notifyDataSetChanged();
    }

    public void setEntries(List<DownloadEntryStore.Entry> entries) {
        this.entries = entries != null ? entries : new ArrayList<>();
        notifyDataSetChanged();
    }

    @Override
    public int getItemCount() {
        return showActive ? jobs.size() : entries.size();
    }

    @Override
    public int getItemViewType(int position) {
        return showActive ? 0 : 1;
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        if (viewType == 0) {
            View v = LayoutInflater.from(context).inflate(R.layout.item_download_active, parent, false);
            return new ActiveHolder(v);
        } else {
            View v = LayoutInflater.from(context).inflate(R.layout.item_download_completed, parent, false);
            return new CompletedHolder(v);
        }
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder h, int pos) {
        if (h instanceof ActiveHolder) {
            ActiveHolder ah = (ActiveHolder) h;
            if (pos < jobs.size()) {
                DownloadManager.Job job = jobs.get(pos);
                String title = job.episodeTitle != null ? job.episodeTitle : job.animeTitle;
                ah.title.setText(title != null ? title : "");
                ah.status.setText(job.status != null ? job.status : "");
                ah.progress.setProgress(Math.max(0, Math.min(100, job.percent)));
                ah.cancelBtn.setOnClickListener(v -> {
                    if (listener != null) listener.onCancel(job);
                });
            }
        } else if (h instanceof CompletedHolder) {
            CompletedHolder ch = (CompletedHolder) h;
            if (pos < entries.size()) {
                DownloadEntryStore.Entry entry = entries.get(pos);
                ch.title.setText(entry.title != null ? entry.title : "");
                ch.parent.setText(entry.parentName());
                ch.size.setText(formatSize(entry.size));
                ch.date.setText(formatDate(entry.completedAt));

                ch.itemView.setOnClickListener(v -> {
                    if (listener != null) listener.onClick(entry);
                });

                if (ch.checkIcon != null) {
                    boolean selected = listener != null && listener.isSelected(entry);
                    ch.checkIcon.setImageResource(selected
                            ? android.R.drawable.checkbox_on_background
                            : android.R.drawable.checkbox_off_background);
                    ch.checkIcon.setOnClickListener(v -> {
                        if (listener != null) listener.onSelectionToggle(entry);
                    });
                }

                ch.deleteBtn.setOnClickListener(v -> {
                    if (listener != null) listener.onDelete(entry);
                });
            }
        }
    }

    private String formatSize(long bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024) + " KB";
        if (bytes < 1024 * 1024 * 1024)
            return String.format(Locale.US, "%.1f MB", bytes / (1024.0 * 1024.0));
        return String.format(Locale.US, "%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0));
    }

    private String formatDate(long millis) {
        return new SimpleDateFormat("MMM dd, yyyy", Locale.US).format(new Date(millis));
    }

    static class ActiveHolder extends RecyclerView.ViewHolder {
        TextView title, status;
        ProgressBar progress;
        ImageView cancelBtn;
        ActiveHolder(View v) {
            super(v);
            title = v.findViewById(R.id.dl_title);
            status = v.findViewById(R.id.dl_status);
            progress = v.findViewById(R.id.dl_progress);
            cancelBtn = v.findViewById(R.id.dl_cancel);
        }
    }

    static class CompletedHolder extends RecyclerView.ViewHolder {
        TextView title, parent, size, date;
        ImageView deleteBtn, checkIcon;
        CompletedHolder(View v) {
            super(v);
            title = v.findViewById(R.id.dl_title);
            parent = v.findViewById(R.id.dl_parent);
            size = v.findViewById(R.id.dl_size);
            date = v.findViewById(R.id.dl_date);
            deleteBtn = v.findViewById(R.id.dl_delete);
            checkIcon = v.findViewById(R.id.dl_check);
        }
    }
}
