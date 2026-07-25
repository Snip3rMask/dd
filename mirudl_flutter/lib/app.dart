import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/detail_provider.dart';
import 'presentation/providers/downloads_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class MiruDlApp extends StatelessWidget {
  const MiruDlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => sl<SearchProvider>(),
        ),
        ChangeNotifierProvider<DetailProvider>(
          create: (_) => sl<DetailProvider>(),
        ),
        ChangeNotifierProvider<DownloadsProvider>(
          create: (_) => sl<DownloadsProvider>(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => sl<SettingsProvider>(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'dd',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
