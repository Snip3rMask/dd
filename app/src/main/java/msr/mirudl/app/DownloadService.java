package msr.mirudl.app;

import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
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

    private final java.util.concurrent.ExecutorService worker =
            java.util.concurrent.Executors.newSingleThreadExecutor();

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
            DownloadManager.Job job = DownloadManager.find(jobId);
            if (job != null) {
                DownloadManager.cancel(job);
                notifyProgress(job);
            }
            if (DownloadManager.activeCount() == 0) {
                stopForeground(false);
                stopSelf();
            }
            return START_NOT_STICKY;
        }

        if (!ACTION_START.equals(action)) return START_NOT_STICKY;

        DownloadManager.setRunning(true);

        startForeground(1001, buildNotification("Starting downloads...", 0, false));

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
        for (DownloadManager.Job job : jobs) {
            if (job.finished) continue;

            DownloadManager.update(job, 0, DownloadManager.STATUS_DOWNLOADING);

            try {
                String playUrl = job.hlsUrl;
                if (playUrl != null && playUrl.contains("/embed/")) {
                    playUrl = AniDbApi.getInstance().resolveHlsFromEmbed(playUrl);
                }

                String output = HlsDownloader.download(
                        this, playUrl,
                        job.animeTitle + " - " + job.episodeTitle,
                        StorageSettings.getParallelSegments(this),
                        (percent, done, total) -> {
                            DownloadManager.update(job, percent, DownloadManager.STATUS_DOWNLOADING);
                            notifyProgress(job);
                        },
                        () -> job.cancelled
                );

                DownloadManager.complete(job, output);
                notifyProgress(job);

            } catch (Exception e) {
                String msg = e.getMessage() != null ? e.getMessage() : "Unknown error";
                DownloadManager.fail(job, msg);
                notifyProgress(job);
            }
        }

        DownloadManager.setRunning(false);
        notifyComplete();
        stopForeground(false);
        stopSelf();
    }

    private void notifyProgress(DownloadManager.Job job) {
        String text = job.episodeTitle != null ? job.episodeTitle : "";
        if (text.isEmpty()) text = job.animeTitle;
        text += " - " + job.percent + "%";
        if (job.finished) {
            text = job.status.equals(DownloadManager.STATUS_COMPLETED)
                    ? "Completed: " + (job.episodeTitle != null ? job.episodeTitle : "")
                    : (job.status != null ? job.status : "Error") + ": " + (job.episodeTitle != null ? job.episodeTitle : "");
        }

        NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (mgr != null) {
            mgr.notify(1001, buildNotification(text, job.percent, job.finished));
        }
    }

    private void notifyComplete() {
        int completed = 0, failed = 0;
        for (DownloadManager.Job j : DownloadManager.snapshot()) {
            if (DownloadManager.STATUS_COMPLETED.equals(j.status)) completed++;
            else if (j.finished) failed++;
        }
        String text = "Done: " + completed + " done";
        if (failed > 0) text += ", " + failed + " failed";
        NotificationManager mgr = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (mgr != null) {
            mgr.notify(1001, buildNotification(text, 100, true));
        }
    }

    private android.app.Notification buildNotification(String text, int progress, boolean done) {
        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(this, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));

        NotificationCompat.Builder b = new NotificationCompat.Builder(this, MiruDLApp.CHANNEL_DOWNLOADS)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle("MiruDL")
                .setContentText(text)
                .setContentIntent(pi)
                .setOnlyAlertOnce(true)
                .setOngoing(!done);

        if (!done) {
            b.setProgress(100, Math.max(0, Math.min(100, progress)), false);
            // Add cancel action in notification like Anifux
            Intent cancelIntent = cancelIntent(this, getFirstActiveJobId());
            PendingIntent cancelPi = PendingIntent.getService(this, 1002, cancelIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));
            b.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelPi);
        } else {
            b.setProgress(0, 0, false);
        }

        return b.build();
    }

    private String getFirstActiveJobId() {
        for (DownloadManager.Job j : DownloadManager.snapshot()) {
            if (!j.finished) return j.id;
        }
        return "";
    }
}
