import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class FolderPickerTile extends StatelessWidget {
  final String? folderPath;
  final VoidCallback onPick;

  const FolderPickerTile({
    super.key,
    required this.folderPath,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Folder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    folderPath != null ? folderPath! : 'Not selected',
                    style: TextStyle(
                      color: folderPath != null
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
