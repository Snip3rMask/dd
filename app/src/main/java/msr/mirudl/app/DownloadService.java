package msr.mirudl.app;

import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.app.NotificationManager;

import androidx.core.app.NotificationCompat;

import java.util.ArrayList;
import java.util.List;

public class DownloadService extends Service {
    private static final String ACTION_START = "start";
    private static final String ACTION_CANCEL = "cancel";
    private static final String EXTRA_JOB_ID = "jobId";
    private static final String EXTRA_JOBS = "jobs";
    private static final int NOTIF_ID = 1001;

    private final java.util.concurrent.ExecutorService worker =
            java.util.concurrent.Executors.newSingleThreadExecutor();
    private volatile boolean processing = false;

    // Track total for multi-episode batch
    private volatile int totalJobCount = 0;
    private final android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());

    public static Intent startIntent(Context context, List<DownloadManager.Job> jobs) {
        Intent intent = new Intent(context, DownloadService.class);
        intent.setAction(ACTION_START);
        intent.putExtra(EXTRA_JOBS, new ArrayList<>(jobs));
        return intent;
    }

    public static Intent cancelIntent(Context context, String jobId) {
        Intent intent = new Intent(context, DownloadService.class);
        intent.setAction(ACTION_CANCEL);
        intent.putExtra(EXTRA_JOB_ID, jobId);
        return intent;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_NOT_STICKY;

        String action = intent.getAction();
        if (ACTION_CANCEL.equals(action)) {
            handleCancel(intent);
            return START_NOT_STICKY;
        }

        if (!ACTION_START.equals(action)) return START_NOT_STICKY;

        // Get active count BEFORE checking processing flag
        int activeJobs = DownloadManager.activeCount();
        if (activeJobs == 0) return START_NOT_STICKY;

        totalJobCount = activeJobs;
        DownloadManager.setRunning(true);

        startForeground(NOTIF_ID, buildNotif(null, totalJobCount + " downloads queued", 0, false));

        processing = true;
        worker.execute(() -> processQueue());
        return START_NOT_STICKY;
    }

    private void handleCancel(Intent intent) {
        String jobId = intent.getStringExtra(EXTRA_JOB_ID);
        if ("all".equals(jobId)) {
            // Cancel all active jobs
            for (DownloadManager.Job j : DownloadManager.snapshot()) {
                if (!j.finished) {
                    DownloadManager.cancel(j);
                }
            }
            pushNotif(buildNotif(null, "Downloads cancelled", 0, true));
            if (DownloadManager.activeCount() == 0) {
                processing = false;
                stopForeground(true);
                stopSelf();
            }
        } else {
            // Cancel specific job
            DownloadManager.Job job = DownloadManager.find(jobId);
            if (job != null) {
                DownloadManager.cancel(job);
                pushNotif(buildNotif(job, "Cancelled", 0, true));
                if (DownloadManager.activeCount() == 0) {
                    processing = false;
                    stopForeground(true);
                    stopSelf();
                }
            }
        }
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onDestroy() {
        worker.shutdownNow();
        DownloadManager.setRunning(false);
        processing = false;
        super.onDestroy();
    }

    private void processQueue() {
        // Safety: if no active jobs, exit immediately
        if (DownloadManager.activeCount() == 0) {
            try { stopForeground(true); } catch (Exception ignored) {}
            try { stopSelf(); } catch (Exception ignored) {}
            processing = false;
            return;
        }
        try {
            int completed = 0, failed = 0, cancelled = 0;

            while (true) {
                // Find next non-finished job
                DownloadManager.Job job = null;
                int jobIndex = 0;
                int totalActive = 0;
                try {
                    List<DownloadManager.Job> snapshot = DownloadManager.snapshot();
                    for (DownloadManager.Job j : snapshot) {
                        if (!j.finished) {
                            totalActive++;
                            if (job == null) {
                                job = j;
                                jobIndex = totalActive;
                            }
                        }
                    }
                } catch (Exception e) {
                    break; // Can't access job list, stop processing
                }

                if (job == null) break; // No more jobs

                // Mark as downloading - wrap in try to avoid crashing the thread
                try {
                    DownloadManager.update(job, 0, DownloadManager.STATUS_DOWNLOADING);
                    String batchInfo = getBatchInfo(jobIndex, totalActive);
                    pushNotif(buildNotif(job, batchInfo + " Starting...", 0, false));
                } catch (Exception ignored) {}

                try {
                    String playUrl = job.hlsUrl;
                    if (playUrl != null && playUrl.contains("/embed/")) {
                        playUrl = MiruClient.getInstance().resolveHlsFromEmbed(playUrl);
                    }

                    final int fJobIndex = jobIndex;
                    final int fTotalActive = totalActive;
                    final DownloadManager.Job currentJob = job;
                    final long[] lastNotifTime = {0};

                    String output = HlsDownloader.download(
                            this, playUrl,
                            job.animeTitle + " - " + job.episodeTitle,
                            StorageSettings.getParallelSegments(this),
                            (percent, done, total) -> {
                                try {
                                    DownloadManager.update(currentJob, percent, DownloadManager.STATUS_DOWNLOADING);
                                    currentJob.percent = percent;
                                    long now = System.currentTimeMillis();
                                    if (now - lastNotifTime[0] >= 500) {
                                        lastNotifTime[0] = now;
                                        String info = getBatchInfo(fJobIndex, fTotalActive);
                                        pushNotif(buildNotif(currentJob, info + " " + percent + "%", percent, false));
                                    }
                                } catch (Exception ignored) {}
                            },
                            () -> currentJob.cancelled
                    );

                    if (job.cancelled) {
                        cancelled++;
                        String info = getBatchInfo(jobIndex, totalActive);
                        pushNotif(buildNotif(job, "\u2716 " + info + " Cancelled", 0, true));
                    } else {
                        DownloadManager.complete(job, output);
                        completed++;
                        String info = getBatchInfo(jobIndex, totalActive);
                        pushNotif(buildNotif(job, "\u2713 " + info + " Done", 100, true));
                    }
                } catch (Exception e) {
                    try {
                        String msg = e.getMessage() != null ? e.getMessage() : "Failed";
                        if (msg.contains("cancelled by user") || msg.contains("Cancelled") || job.cancelled) {
                            DownloadManager.cancel(job);
                            cancelled++;
                        } else {
                            DownloadManager.fail(job, msg);
                            failed++;
                        }
                        String info = getBatchInfo(jobIndex, totalActive);
                        pushNotif(buildNotif(job, "\u2716 " + info + " " + msg, 0, true));
                    } catch (Exception ignored) {}
                }
            }

            try {
                DownloadManager.setRunning(false);

                String summary = "\u2713 " + completed + " done";
                if (failed > 0) summary += ", \u2716 " + failed + " failed";
                if (cancelled > 0) summary += ", cancelled " + cancelled;
                if (completed + failed + cancelled > 0) {
                    pushNotif(buildNotif(null, summary, 100, true));
                }

                mainHandler.postDelayed(() -> {
                    try {
                        NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
                        if (mgr != null) mgr.cancel(NOTIF_ID);
                    } catch (Exception ignored) {}
                }, 5000);

                stopForeground(true);
                stopSelf();
            } catch (Exception ignored) {}
        } finally {
            // ALWAYS reset processing flag to prevent stuck downloads
            DownloadManager.setRunning(false);
            processing = false;
        }
    }

    /** Helper to show "[3/12]" style batch progress */
    private String getBatchInfo(int current, int total) {
        if (total <= 1) return "";
        return "[" + current + "/" + total + "]";
    }

    /** Push notification using job info */
    private void pushNotif(android.app.Notification notif) {
        NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (mgr != null) mgr.notify(NOTIF_ID, notif);
    }

    /** Build a notification from a Job (title + text + progress) */
    private android.app.Notification buildNotif(DownloadManager.Job job, String text, int progress, boolean done) {
        String title = "MiruDL";
        String subText = "";
        if (job != null && job.animeTitle != null) {
            title = job.animeTitle;
            if (job.episodeTitle != null) {
                subText = job.episodeTitle;
            }
        }

        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(this, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | (android.os.Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));

        NotificationCompat.Builder b = new NotificationCompat.Builder(this, MiruDLApp.CHANNEL_DOWNLOADS)
                .setSmallIcon(done ? android.R.drawable.stat_sys_download_done : android.R.drawable.stat_sys_download)
                .setContentTitle(title)
                .setContentText(text)
                .setSubText(subText)
                .setContentIntent(pi)
                .setOnlyAlertOnce(true)
                .setOngoing(!done);

        if (!done) {
            b.setProgress(100, Math.max(0, Math.min(100, progress)), false);

            // Cancel ALL action via BroadcastReceiver
            Intent cancelIntent = new Intent(this, CancelDownloadReceiver.class);
            cancelIntent.putExtra("jobId", "all");
            PendingIntent cancelPi = PendingIntent.getBroadcast(this, 1002, cancelIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));
            b.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel All", cancelPi);
        } else {
            b.setProgress(0, 0, false);
        }

        return b.build();
    }

    /** Overload for backward compat – builds a notification directly from job state */
    private android.app.Notification buildNotif(DownloadManager.Job job) {
        if (job == null) {
            return buildNotif(null, "Starting...", 0, false);
        }
        String text;
        if (job.finished) {
            text = job.status != null ? job.status : "Done";
        } else {
            text = job.episodeTitle + " - " + job.percent + "%";
        }
        return buildNotif(job, text, job.percent, job.finished);
    }

}
