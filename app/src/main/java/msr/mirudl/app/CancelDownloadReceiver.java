package msr.mirudl.app;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class CancelDownloadReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String jobId = intent.getStringExtra("jobId");
        if (jobId == null) return;

        // Cancel all active jobs
        for (DownloadManager.Job j : DownloadManager.snapshot()) {
            if (!j.finished) {
                DownloadManager.cancel(j);
            }
        }

        // Update notification to show cancelled
        NotificationManager mgr = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (mgr != null) {
            android.app.Notification.Builder b = new android.app.Notification.Builder(context, MiruDLApp.CHANNEL_DOWNLOADS)
                    .setSmallIcon(android.R.drawable.stat_sys_download)
                    .setContentTitle("MiruDL")
                    .setContentText("Downloads cancelled")
                    .setOngoing(false)
                    .setProgress(0, 0, false);
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                b.setSmallIcon(android.R.drawable.ic_menu_close_clear_cancel);
            }
            mgr.notify(1001, b.build());
        }

        // Stop the download service
        Intent stopIntent = new Intent(context, DownloadService.class);
        context.stopService(stopIntent);
    }
}
