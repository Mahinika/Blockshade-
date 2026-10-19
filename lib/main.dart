import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'screens/startup_error_screen.dart';
import 'utils/recoverable_errors.dart';

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    if (isRecoverableAsyncError(details.exception)) {
      debugPrint('Recoverable FlutterError: ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
    runApp(
      StartupErrorScreen(
        message: 'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (isRecoverableAsyncError(error)) {
      debugPrint('Recoverable platform error: $error');
      return true;
    }
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
      if (isRecoverableAsyncError(error)) {
        debugPrint('Recoverable zone error: $error\n$stack');
        return;
      }
      runApp(
        StartupErrorScreen(
          message: 'runZonedGuarded: $error\n$stack',
        ),
      );
    },
  );
}
