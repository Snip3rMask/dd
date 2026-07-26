import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/detail_provider.dart';
import 'presentation/providers/downloads_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/theme/app_theme.dart';

/// Navigator observer that tracks the current screen for crash logs
class ScreenTracker extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateScreen(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _updateScreen(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _updateScreen(newRoute);
  }

  void _updateScreen(Route route) {
    try {
      String name = route.settings.name ?? route.toString();
      Logger.instance.currentScreen = name;
    } catch (_) {
      // Navigation tracking should never crash the app
    }
  }
}

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
            navigatorObservers: [ScreenTracker()],
          );
        },
      ),
    );
  }
}
