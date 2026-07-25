import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';

class ParallelSegmentsSlider extends StatelessWidget {
  final int value;
  final ValueChanged<double> onChanged;

  const ParallelSegmentsSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Parallel Segments'),
                const Spacer(),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: AppConstants.maxParallel.toDouble(),
              divisions: AppConstants.maxParallel - 1,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceLight,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
