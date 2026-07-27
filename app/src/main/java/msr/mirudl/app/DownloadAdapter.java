package msr.mirudl.app;

import android.content.Context;
import android.graphics.Typeface;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class DownloadAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private static final int TYPE_SECTION = 0;
    private static final int TYPE_GROUP = 1;
    private static final int TYPE_ACTIVE = 2;
    private static final int TYPE_COMPLETED = 3;

    private final Context context;
    private final List<Object> items = new ArrayList<>();
    private final OnActionListener listener;

    public interface OnActionListener {
        default void onCancel(DownloadManager.Job job) {}
        default void onClick(DownloadEntryStore.Entry entry) {}
        default void onDelete(DownloadEntryStore.Entry entry) {}
        default void onSelectionToggle(DownloadEntryStore.Entry entry) {}
        default boolean isSelected(DownloadEntryStore.Entry entry) { return false; }
        default void onGroupDelete(String groupName) {}
    }

    public DownloadAdapter(Context context, OnActionListener listener) {
        this.context = context;
        this.listener = listener;
    }

    public void setData(List<DownloadManager.Job> jobs, List<DownloadEntryStore.Entry> entries) {
        items.clear();

        // Active section
        boolean hasActive = false;
        for (DownloadManager.Job j : jobs) {
            if (!j.finished) { hasActive = true; break; }
        }

        if (hasActive) {
            items.add(new SectionHeader("DOWNLOADING"));
            for (DownloadManager.Job job : jobs) {
                if (!job.finished) {
                    items.add(job);
                }
            }
        }

        // Completed section - grouped by anime folder
        if (entries != null && !entries.isEmpty()) {
            // Group by parent (anime name)
            Map<String, List<DownloadEntryStore.Entry>> grouped = new LinkedHashMap<>();
            for (DownloadEntryStore.Entry e : entries) {
                String parent = e.parentName();
                grouped.computeIfAbsent(parent, k -> new ArrayList<>()).add(e);
            }

            items.add(new SectionHeader("COMPLETED"));

            // Create expand/collapse tracking
            if (expandedFolders == null) {
                expandedFolders = new java.util.HashSet<>();
            }

            for (Map.Entry<String, List<DownloadEntryStore.Entry>> group : grouped.entrySet()) {
                String folderName = group.getKey();
                List<DownloadEntryStore.Entry> folderEntries = group.getValue();
                boolean isExpanded = expandedFolders.contains(folderName);

                items.add(new GroupHeader(folderName, folderEntries.size(), isExpanded));

                if (isExpanded) {
                    for (DownloadEntryStore.Entry e : folderEntries) {
                        items.add(e);
                    }
                }
            }
        }

        // Empty state
        if (items.isEmpty()) {
            items.add(new EmptyState());
        }

        notifyDataSetChanged();
    }

    private java.util.Set<String> expandedFolders = new java.util.HashSet<>();

    public void toggleFolder(String folderName) {
        if (expandedFolders.contains(folderName)) {
            expandedFolders.remove(folderName);
        } else {
            expandedFolders.add(folderName);
        }
        // Rebuild items with new expand state
        // We need the current jobs and entries, but we don't have them here
        // The caller should call setData() again
    }

    public boolean isFolderExpanded(String folderName) {
        return expandedFolders.contains(folderName);
    }

    @Override
    public int getItemCount() { return items.size(); }

    @Override
    public int getItemViewType(int position) {
        Object item = items.get(position);
        if (item instanceof SectionHeader) return TYPE_SECTION;
        if (item instanceof GroupHeader) return TYPE_GROUP;
        if (item instanceof DownloadManager.Job) return TYPE_ACTIVE;
        if (item instanceof DownloadEntryStore.Entry) return TYPE_COMPLETED;
        return TYPE_SECTION;
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(context);
        switch (viewType) {
            case TYPE_SECTION:
                return new SectionHolder(inflater.inflate(R.layout.item_section_header, parent, false));
            case TYPE_GROUP:
                return new GroupHolder(inflater.inflate(R.layout.item_group_header, parent, false));
            case TYPE_ACTIVE:
                return new ActiveHolder(inflater.inflate(R.layout.item_download_active, parent, false));
            case TYPE_COMPLETED:
                return new CompletedHolder(inflater.inflate(R.layout.item_download_completed, parent, false));
        }
        return new SectionHolder(inflater.inflate(R.layout.item_section_header, parent, false));
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder h, int pos) {
        Object item = items.get(pos);
        if (h instanceof SectionHolder) {
            ((SectionHolder) h).text.setText(item.toString());
        } else if (h instanceof GroupHolder) {
            GroupHeader gh = (GroupHeader) item;
            GroupHolder ghHolder = (GroupHolder) h;
            ghHolder.title.setText(gh.name);
            ghHolder.count.setText(gh.count + " episode" + (gh.count > 1 ? "s" : ""));
            ghHolder.expandIcon.setImageResource(gh.expanded
                    ? android.R.drawable.arrow_up_float
                    : android.R.drawable.arrow_down_float);
            ghHolder.itemView.setOnClickListener(v -> {
                toggleFolder(gh.name);
                // Need to rebuild - caller should call setData
                if (listener != null) listener.onGroupDelete(gh.name); // reuse onGroupDelete to signal rebuild
            });
        } else if (h instanceof ActiveHolder) {
            ActiveHolder ah = (ActiveHolder) h;
            DownloadManager.Job job = (DownloadManager.Job) item;
            ah.animeTitle.setText(job.animeTitle != null ? job.animeTitle : "");
            ah.episodeTitle.setText(job.episodeTitle != null ? job.episodeTitle : "");
            ah.status.setText(job.status != null ? job.status : "");
            ah.progress.setProgress(Math.max(0, Math.min(100, job.percent)));
            ah.cancelBtn.setOnClickListener(v -> {
                if (listener != null) listener.onCancel(job);
            });
        } else if (h instanceof CompletedHolder) {
            CompletedHolder ch = (CompletedHolder) h;
            DownloadEntryStore.Entry entry = (DownloadEntryStore.Entry) item;
            ch.title.setText(entry.title != null ? entry.title : "");
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

    // ============ VIEW HOLDERS ============

    static class SectionHolder extends RecyclerView.ViewHolder {
        TextView text;
        SectionHolder(View v) { super(v); text = (TextView) v; }
    }

    static class GroupHolder extends RecyclerView.ViewHolder {
        TextView title, count;
        ImageView expandIcon;
        GroupHolder(View v) {
            super(v);
            title = v.findViewById(R.id.group_title);
            count = v.findViewById(R.id.group_count);
            expandIcon = v.findViewById(R.id.group_expand);
        }
    }

    static class ActiveHolder extends RecyclerView.ViewHolder {
        TextView animeTitle, episodeTitle, status;
        ProgressBar progress;
        ImageView cancelBtn;
        ActiveHolder(View v) {
            super(v);
            animeTitle = v.findViewById(R.id.dl_anime);
            episodeTitle = v.findViewById(R.id.dl_title);
            status = v.findViewById(R.id.dl_status);
            progress = v.findViewById(R.id.dl_progress);
            cancelBtn = v.findViewById(R.id.dl_cancel);
        }
    }

    static class CompletedHolder extends RecyclerView.ViewHolder {
        TextView title, size, date;
        ImageView deleteBtn, checkIcon;
        CompletedHolder(View v) {
            super(v);
            title = v.findViewById(R.id.dl_title);
            size = v.findViewById(R.id.dl_size);
            date = v.findViewById(R.id.dl_date);
            deleteBtn = v.findViewById(R.id.dl_delete);
            checkIcon = v.findViewById(R.id.dl_check);
        }
    }

    // ============ ITEM TYPES ============

    static class SectionHeader {
        final String name;
        SectionHeader(String name) { this.name = name; }
        @Override public String toString() { return name; }
    }

    static class GroupHeader {
        final String name;
        final int count;
        final boolean expanded;
        GroupHeader(String name, int count, boolean expanded) {
            this.name = name; this.count = count; this.expanded = expanded;
        }
    }

    static class EmptyState {
        @Override public String toString() { return "No downloads yet"; }
    }

    // ============ HELPERS ============

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
}
