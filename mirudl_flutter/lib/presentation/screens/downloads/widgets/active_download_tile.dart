import 'package:flutter/material.dart';
import '../../../../data/repositories/download_repository.dart';
import '../../../../domain/enums/download_status.dart';
import '../../../theme/app_colors.dart';

class ActiveDownloadTile extends StatelessWidget {
  final DownloadJob job;
  final VoidCallback onCancel;

  const ActiveDownloadTile({
    super.key,
    required this.job,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.episodeTitle.isNotEmpty
                        ? job.episodeTitle
                        : job.animeTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.error,
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              job.status.label,
              style: TextStyle(
                color: _statusColor(job.status),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: job.percent / 100.0,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${job.percent}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.cancelled:
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }
}
