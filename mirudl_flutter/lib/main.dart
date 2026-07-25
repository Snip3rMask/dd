import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'di/service_locator.dart';
import 'services/background_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize global error handler
  FlutterError.onError = (details) {
    Logger.instance.logException(details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Logger.instance.logException(error, stack);
    return true;
  };

  // Initialize dependency injection (includes services)
  await setupServiceLocator();

  // Initialize background service
  final bgService = sl<BackgroundService>();
  await bgService.init();

  runApp(const MiruDlApp());
}
