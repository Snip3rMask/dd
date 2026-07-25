import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/utils/permissions.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/folder_picker_tile.dart';
import 'widgets/quality_selector.dart';
import 'widgets/language_selector.dart';
import 'widgets/parallel_segments_slider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickFolder() async {
    // Request storage permission first
    final hasPermission = await AppPermissions.requestStorage();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Storage permission is needed to select a download folder. '
              'Please grant it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Pick a directory
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
    );

    if (result != null && mounted) {
      context.read<SettingsProvider>().setFolderPath(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Folder picker
              Text(
                'STORAGE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              FolderPickerTile(
                folderPath: provider.folderPath,
                onPick: _pickFolder,
              ),

              const SizedBox(height: 24),

              // Theme toggle
              Text(
                'APPEARANCE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    provider.darkMode ? 'Dark theme active' : 'Light theme active',
                  ),
                  value: provider.darkMode,
                  onChanged: (_) => provider.toggleTheme(),
                  secondary: Icon(
                    provider.darkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Download settings
              Text(
                'DOWNLOAD',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ParallelSegmentsSlider(
                value: provider.parallel,
                onChanged: (val) => provider.setParallel(val.round()),
              ),
              QualitySelector(
                selectedQuality: provider.quality,
                onChanged: (val) {
                  if (val != null) provider.setQuality(val);
                },
              ),
              LanguageSelector(
                selectedLanguage: provider.language,
                onChanged: (val) {
                  if (val != null) provider.setLanguage(val);
                },
              ),

              const SizedBox(height: 32),

              // About section
              Text(
                'ABOUT',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Card(
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
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('dd'),
                          SizedBox(height: 2),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
