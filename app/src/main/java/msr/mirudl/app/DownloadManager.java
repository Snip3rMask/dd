package msr.mirudl.app;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public final class DownloadManager {
    public static final String STATUS_QUEUED = "Queued";
    public static final String STATUS_DOWNLOADING = "Downloading";
    public static final String STATUS_COMPLETED = "Completed";
    public static final String STATUS_FAILED = "Failed";
    public static final String STATUS_CANCELLED = "Cancelled";

    public static class Job implements Serializable {
        private static final long serialVersionUID = 1L;
        public final String id;
        public final String animeTitle;
        public String episodeTitle;
        public final String quality;
        public final String language;
        public final String hlsUrl;
        public volatile int percent;
        public volatile String status;
        public volatile boolean cancelled;
        public volatile boolean finished;
        public volatile String error;
        public String outputUri;

        public Job(String animeTitle, String episodeTitle, String quality,
                   String language, String hlsUrl) {
            this.id = UUID.randomUUID().toString();
            this.animeTitle = animeTitle;
            this.episodeTitle = episodeTitle;
            this.quality = quality;
            this.language = language;
            this.hlsUrl = hlsUrl;
            this.status = STATUS_QUEUED;
        }
    }

    private static final List<Job> JOBS = Collections.synchronizedList(new ArrayList<>());
    private static volatile boolean running = false;

    public static synchronized Job enqueue(String anime, String episode, String quality,
                                            String language, String hlsUrl) {
        Job job = new Job(anime, episode, quality, language, hlsUrl);
        JOBS.add(job);
        return job;
    }

    public static synchronized void enqueueAll(List<Job> jobs) {
        JOBS.addAll(jobs);
    }

    public static synchronized Job find(String id) {
        for (Job j : JOBS) if (id.equals(j.id)) return j;
        return null;
    }

    public static synchronized void update(Job job, int percent, String status) {
        if (job == null) return;
        job.percent = percent;
        job.status = status;
    }

    public static synchronized void complete(Job job, String outputUri) {
        if (job == null) return;
        job.percent = 100;
        job.status = STATUS_COMPLETED;
        job.finished = true;
        job.outputUri = outputUri;
    }

    public static synchronized void fail(Job job, String error) {
        if (job == null) return;
        job.error = error;
        job.status = error != null ? error : STATUS_FAILED;
        job.finished = true;
    }

    public static synchronized void cancel(Job job) {
        if (job == null) return;
        job.cancelled = true;
        job.status = STATUS_CANCELLED;
        job.finished = true;
    }

    public static synchronized void remove(Job job) {
        JOBS.remove(job);
    }

    public static synchronized void removeFinished() {
        JOBS.removeIf(j -> j.finished);
    }

    public static synchronized List<Job> snapshot() {
        return new ArrayList<>(JOBS);
    }

    public static synchronized int activeCount() {
        int count = 0;
        for (Job j : JOBS)
            if (!j.finished) count++;
        return count;
    }

    public static synchronized boolean isRunning() {
        return running;
    }

    public static synchronized void setRunning(boolean r) {
        running = r;
    }
}
