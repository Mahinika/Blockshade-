import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'screens/startup_error_screen.dart';

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    runApp(
      StartupErrorScreen(
        message: 'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    runApp(
      StartupErrorScreen(
        message: 'PlatformDispatcher: $error\n$stack',
      ),
    );
    return true;
  };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  runZonedGuarded(
    () {
      runApp(const BlockshadeBootstrap());
    },
    (error, stack) {
      runApp(
        StartupErrorScreen(
          message: 'runZonedGuarded: $error\n$stack',
        ),
      );
    },
  );
}
