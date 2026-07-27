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
            String jobId = intent.getStringExtra(EXTRA_JOB_ID);
            if ("all".equals(jobId)) {
                // Cancel all active jobs
                for (DownloadManager.Job j : DownloadManager.snapshot()) {
                    if (!j.finished) {
                        DownloadManager.cancel(j);
                    }
                }
            } else {
                DownloadManager.Job job = DownloadManager.find(jobId);
                if (job != null) {
                    DownloadManager.cancel(job);
                }
            }
            pushNotif(buildNotif(null, "Downloads cancelled", 0, true));
            if (DownloadManager.activeCount() == 0) {
                stopForeground(true);
                stopSelf();
            }
            return START_NOT_STICKY;
        }

        if (!ACTION_START.equals(action)) return START_NOT_STICKY;

        List<DownloadManager.Job> jobs = (List<DownloadManager.Job>)
                intent.getSerializableExtra(EXTRA_JOBS);
        if (jobs == null || jobs.isEmpty()) return START_NOT_STICKY;

        totalJobCount = jobs.size();
        DownloadManager.setRunning(true);

        startForeground(NOTIF_ID, buildNotif(null, "Starting " + totalJobCount + " downloads...", 0, false));

        worker.execute(() -> processQueue());
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onDestroy() {
        worker.shutdownNow();
        DownloadManager.setRunning(false);
        super.onDestroy();
    }

    private void processQueue() {
        List<DownloadManager.Job> jobs = DownloadManager.snapshot();
        int completed = 0, failed = 0;

        for (int i = 0; i < jobs.size(); i++) {
            DownloadManager.Job job = jobs.get(i);
            if (job.finished) continue;

            // Immediately show "Downloading X of Y" in notification
            String batchInfo = getBatchInfo(i + 1);
            DownloadManager.update(job, 0, DownloadManager.STATUS_DOWNLOADING);
            pushNotif(buildNotif(job, batchInfo + " Starting...", 0, false));

            try {
                String playUrl = job.hlsUrl;
                if (playUrl != null && playUrl.contains("/embed/")) {
                    playUrl = MiruClient.getInstance().resolveHlsFromEmbed(playUrl);
                }

                final int jobIndex = i;
                String output = HlsDownloader.download(
                        this, playUrl,
                        job.animeTitle + " - " + job.episodeTitle,
                        StorageSettings.getParallelSegments(this),
                        (percent, done, total) -> {
                            // Real-time progress update
                            DownloadManager.update(job, percent, DownloadManager.STATUS_DOWNLOADING);
                            String info = getBatchInfo(jobIndex + 1);
                            pushNotif(buildNotif(job, info + " " + percent + "%", percent, false));
                        },
                        () -> job.cancelled
                );

                DownloadManager.complete(job, output);
                completed++;
                // Show completed notification immediately
                String info = getBatchInfo(jobIndex + 1);
                pushNotif(buildNotif(job, "\u2713 " + info + " Done", 100, true));

            } catch (Exception e) {
                String msg = e.getMessage() != null ? e.getMessage() : "Failed";
                // If cancelled by user, mark as cancelled instead of failed
                if (msg.contains("cancelled by user") || msg.contains("Cancelled")) {
                    DownloadManager.cancel(job);
                } else {
                    DownloadManager.fail(job, msg);
                    failed++;
                }
                String info = getBatchInfo(i + 1);
                pushNotif(buildNotif(job, "\u2716 " + info + " " + msg, 0, true));
            }
        }

        DownloadManager.setRunning(false);

        // Final summary
        String summary = "\u2713 " + completed + " done";
        if (failed > 0) summary += ", \u2716 " + failed + " failed";
        if (completed + failed > 0) {
            pushNotif(buildNotif(null, summary, 100, true));
        }

        // Auto-cancel notification after 5 seconds
        mainHandler.postDelayed(() -> {
            NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (mgr != null) mgr.cancel(NOTIF_ID);
        }, 5000);

        stopForeground(true);
        stopSelf();
    }

    /** Helper to show "[3/12]" style batch progress */
    private String getBatchInfo(int current) {
        if (totalJobCount <= 1) return "";
        return "[" + current + "/" + totalJobCount + "]";
    }

    /** Push notification using job info */
    private void pushNotif(android.app.Notification notif) {
        NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (mgr != null) mgr.notify(NOTIF_ID, notif);
    }

    /** Build a notification from a Job (title + text + progress) */
    private android.app.Notification buildNotif(DownloadManager.Job job, String text, int progress, boolean done) {
        String title = "MiruDL";
        if (job != null && job.animeTitle != null) {
            title = job.animeTitle;
        }

        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(this, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | (android.os.Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));

        NotificationCompat.Builder b = new NotificationCompat.Builder(this, MiruDLApp.CHANNEL_DOWNLOADS)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pi)
                .setOnlyAlertOnce(true)
                .setOngoing(!done);

        if (!done) {
            b.setProgress(100, Math.max(0, Math.min(100, progress)), false);

            // Cancel action via BroadcastReceiver (more reliable than getService)
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
