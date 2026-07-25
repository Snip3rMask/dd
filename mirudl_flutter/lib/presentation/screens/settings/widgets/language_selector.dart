import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String?> onChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
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
                Icons.language_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Audio Language')),
            DropdownButton<String>(
              value: selectedLanguage,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'jpn', child: Text('Sub (Japanese)')),
                DropdownMenuItem(value: 'eng', child: Text('Dub (English)')),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
