import 'package:flutter/services.dart';

/// Errors that should not replace the whole app with the fatal error screen.
bool isRecoverableAsyncError(Object error) {
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('sharedpreferences') ||
        message.contains('sharedpreferences') ||
        message.contains('nosuchmethoderror')) {
      return true;
    }
  }
  final text = error.toString().toLowerCase();
  return text.contains('sharedpreferences') ||
      text.contains('sharedpreferencesapiregistrar') ||
      (text.contains('nosuchmethoderror') && text.contains('getall'));
}
