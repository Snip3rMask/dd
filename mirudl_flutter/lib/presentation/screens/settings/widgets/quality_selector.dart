import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';

class QualitySelector extends StatelessWidget {
  final String selectedQuality;
  final ValueChanged<String?> onChanged;

  const QualitySelector({
    super.key,
    required this.selectedQuality,
    required this.onChanged,
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
                Icons.high_quality_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Preferred Quality'),
            const Spacer(),
            DropdownButton<String>(
              value: selectedQuality,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              underline: const SizedBox(),
              items: AppConstants.qualities.map((q) {
                return DropdownMenuItem(value: q, child: Text(q));
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
