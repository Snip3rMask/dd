package com.mirudl.flutter

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupNativeCrashHandler()
    }

    /**
     * Set up a default uncaught exception handler that writes crash
     * reports to the app's documents directory so that the Dart
     * Logger can pick them up.
     */
    private fun setupNativeCrashHandler() {
        val existingHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                writeCrashReport(throwable)
            } catch (_: Exception) {
                // Silently fall back to default handler
            }
            // Always delegate to the existing handler (or the system one)
            existingHandler?.uncaughtException(thread, throwable)
                ?: throwable.printStackTrace()
        }
    }

    private fun writeCrashReport(throwable: Throwable) {
        try {
            val crashDir = File(filesDir, "crash_logs")
            crashDir.mkdirs()

            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
                .format(Date())
            val id = System.currentTimeMillis()
            val deviceModel = "${Build.BRAND} ${Build.MODEL}"
            val osVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

            val sw = StringWriter()
            val pw = PrintWriter(sw)
            throwable.printStackTrace(pw)
            pw.flush()
            val stackTrace = sw.toString()

            val report = buildString {
                appendLine("══════════════════════════════════════════════")
                appendLine("            CRASH REPORT")
                appendLine("══════════════════════════════════════════════")
                appendLine()
                appendLine("DEVICE INFO")
                appendLine("  Device      : $deviceModel")
                appendLine("  OS Version  : $osVersion")
                appendLine()
                appendLine("WHEN")
                appendLine("  Timestamp   : $timestamp")
                appendLine("  Screen      : NativeAndroid")
                appendLine()
                appendLine("EXCEPTION")
                appendLine("  Type  : ${throwable.javaClass.name}")
                appendLine("  Message: ${throwable.message ?: "No message"}")
                appendLine()
                appendLine("STACK TRACE")
                appendLine(stackTrace)
                appendLine()
                appendLine("══════════════════════════════════════════════")
            }

            val file = File(crashDir, "crash_$id.txt")
            FileWriter(file).use { writer ->
                writer.write(report)
            }
        } catch (_: Exception) {
            // Can't do much if the crash handler itself crashes
        }
    }
}
