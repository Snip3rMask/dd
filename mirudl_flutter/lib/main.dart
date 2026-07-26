import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'app.dart';
import 'di/service_locator.dart';
import 'services/background_service.dart';
import 'core/utils/logger.dart';
import 'core/utils/permissions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize crash logger first
  await Logger.instance.init();

  // Global error handlers — capture every crash with full context
  FlutterError.onError = (details) {
    Logger.instance.logException(
      details.exception,
      details.stack,
      screen: 'FlutterError',
    );
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    Logger.instance.logException(error, stack, screen: 'PlatformDispatcher');
    return true;
  };

  // Zone-level catch for all async errors
  runZonedGuarded(() async {
    await setupServiceLocator();

    // Request notification permission (Android 13+)
    await AppPermissions.hasNotificationPermission();

    final bgService = sl<BackgroundService>();
    await bgService.init();

    runApp(const MiruDlApp());
  }, (error, stack) {
    Logger.instance.logException(error, stack, screen: 'AppZone');
  });
}
