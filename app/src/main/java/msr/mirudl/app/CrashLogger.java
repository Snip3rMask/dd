package msr.mirudl.app;

import android.content.Context;
import android.os.Build;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class CrashLogger implements Thread.UncaughtExceptionHandler {
    private static final String CRASH_DIR = "crash_logs";
    private final Context context;
    private final Thread.UncaughtExceptionHandler defaultHandler;

    public CrashLogger(Context context) {
        this.context = context.getApplicationContext();
        this.defaultHandler = Thread.getDefaultUncaughtExceptionHandler();
    }

    public static void init(Context context) {
        Thread.setDefaultUncaughtExceptionHandler(new CrashLogger(context));
    }

    public static void saveCaughtException(Context context, Thread thread, Throwable ex) {
        File dir = new File(context.getApplicationContext().getExternalFilesDir(null), CRASH_DIR);
        if (!dir.exists()) dir.mkdirs();
        String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US).format(new Date());
        File file = new File(dir, "crash_" + timestamp + ".txt");
        try (BufferedWriter w = new BufferedWriter(new FileWriter(file))) {
            w.write("=== CRASH REPORT ===\n");
            w.write("Time: " + timestamp + "\n");
            w.write("SDK: " + Build.VERSION.SDK_INT + "\n");
            w.write("Device: " + Build.MANUFACTURER + " " + Build.MODEL + "\n\n");
            w.write("--- EXCEPTION ---\n");
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            ex.printStackTrace(pw);
            pw.flush();
            w.write(sw.toString());
            w.flush();
        } catch (Exception ignored) {}
    }

    @Override
    public void uncaughtException(Thread thread, Throwable ex) {
        try {
            saveCrashLog(thread, ex);
        } catch (Exception ignored) {}
        if (defaultHandler != null) {
            defaultHandler.uncaughtException(thread, ex);
        }
    }

    private void saveCrashLog(Thread thread, Throwable ex) {
        saveCaughtException(context, thread, ex);
    }
}
