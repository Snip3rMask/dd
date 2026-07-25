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

  FlutterError.onError = (details) {
    Logger.instance.logException(details.exception, details.stack);
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    Logger.instance.logException(error, stack);
    return true;
  };

  await setupServiceLocator();

  // Request notification permission (Android 13+)
  await AppPermissions.hasNotificationPermission();

  final bgService = sl<BackgroundService>();
  await bgService.init();

  runApp(const MiruDlApp());
}
