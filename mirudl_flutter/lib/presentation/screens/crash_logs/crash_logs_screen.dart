import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/utils/logger.dart';
import '../../theme/app_colors.dart';

class CrashLogsScreen extends StatefulWidget {
  const CrashLogsScreen({super.key});

  @override
  State<CrashLogsScreen> createState() => _CrashLogsScreenState();
}

class _CrashLogsScreenState extends State<CrashLogsScreen> {
  List<CrashEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = Logger.instance.getCrashLogs();
      _isLoading = false;
    });
  }

  Future<void> _viewLog(CrashEntry entry) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrashLogDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Crash Logs',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to delete all crash logs?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Logger.instance.clearAll();
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Logs'),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _buildEmptyState()
              : _buildLogList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: AppColors.secondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No Crash Logs',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your app is running smoothly! 🎉',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final isLatest = index == 0;
        return Card(
          color: isLatest && log.exceptionType != 'Unknown'
              ? AppColors.error.withOpacity(0.08)
              : AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _viewLog(log),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isLatest
                          ? AppColors.error.withOpacity(0.15)
                          : AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bug_report,
                      color: isLatest ? AppColors.error : AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.exceptionType,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.timestamp,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          log.screenName,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full crash log detail with copy/share/download
class CrashLogDetailScreen extends StatelessWidget {
  final CrashEntry entry;

  const CrashLogDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final report = entry.formattedReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crash report copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share report',
            onPressed: () => _shareReport(context, report),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download report',
            onPressed: () => _downloadReport(context, report),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          report,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _shareReport(BuildContext context, String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report copied! Paste it anywhere to share.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _downloadReport(BuildContext context, String report) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/crash_reports/crash_${entry.id}.txt',
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(report);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
