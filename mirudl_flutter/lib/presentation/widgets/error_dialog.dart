import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable error dialog
class ErrorDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'OK',
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: message != null
            ? Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss?.call();
            },
            child: Text(
              buttonText,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a startup/blocking error with exit option
  static Future<void> showFatal({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
