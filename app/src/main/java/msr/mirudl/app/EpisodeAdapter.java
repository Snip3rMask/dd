package msr.mirudl.app;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

public class EpisodeAdapter extends RecyclerView.Adapter<EpisodeAdapter.ViewHolder> {
    private List<EpisodeItem> items = new ArrayList<>();
    private final OnEpisodeClickListener listener;

    public interface OnEpisodeClickListener {
        void onClick(EpisodeItem episode);
    }

    public EpisodeAdapter(OnEpisodeClickListener listener) {
        this.listener = listener;
    }

    public void setItems(List<EpisodeItem> items) {
        this.items = items != null ? items : new ArrayList<>();
        notifyDataSetChanged();
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_episode, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(ViewHolder h, int pos) {
        EpisodeItem ep = items.get(pos);
        h.epNum.setText(ep.getLabel());
        h.title.setText("Episode " + ep.getLabel());
        if (ep.filler) {
            h.title.setText("Episode " + ep.getLabel() + " [FILLER]");
            h.title.setTextColor(0xFFA0A0B0);
        } else {
            h.title.setTextColor(0xFFFAFAFA);
        }
        h.downloadIcon.setVisibility(View.VISIBLE);
        h.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(ep);
        });
    }

    @Override
    public int getItemCount() { return items.size(); }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView epNum, title;
        ImageView downloadIcon;
        ViewHolder(View v) {
            super(v);
            epNum = v.findViewById(R.id.ep_number);
            title = v.findViewById(R.id.ep_title);
            downloadIcon = v.findViewById(R.id.ep_download);
        }
    }
}
