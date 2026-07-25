import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/downloads_provider.dart';
import '../../widgets/empty_state.dart';
import 'widgets/active_download_tile.dart';
import 'widgets/completed_download_tile.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadsProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Provider will handle cleanup via its own dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<DownloadsProvider>(
        builder: (context, provider, _) {
          final active = provider.activeJobs;
          final completed = provider.completed;

          if (!provider.hasActive && !provider.hasCompleted) {
            return const EmptyState(
              icon: Icons.download_outlined,
              message: 'No downloads yet',
              subtitle: 'Downloads will appear here',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active downloads section
              if (provider.hasActive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Downloads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${active.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...active.map((job) => ActiveDownloadTile(
                      job: job,
                      onCancel: () => provider.cancelJob(job.id),
                    )),
                const SizedBox(height: 24),
              ],

              // Completed section
              if (provider.hasCompleted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        if (completed.isEmpty) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear History'),
                            content: const Text(
                                'Remove all download history?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  provider.clearHistory();
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...completed.map((entry) => CompletedDownloadTile(
                      entry: entry,
                      onTap: () {
                        // Open file — platform specific
                      },
                      onDelete: () => provider.removeEntry(entry),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
