import 'dart:async';

/// Runs [action] with a ceiling; returns [fallback] on timeout or error.
Future<T> startupWithTimeout<T>(
  Future<T> action, {
  required Duration timeout,
  required T fallback,
  String? debugLabel,
}) async {
  try {
    return await action.timeout(timeout);
  } catch (e) {
    // ignore: avoid_print
    print('Startup timeout/error${debugLabel != null ? ' ($debugLabel)' : ''}: $e');
    return fallback;
  }
}

/// Like [startupWithTimeout] for void futures.
Future<void> startupWithTimeoutVoid(
  Future<void> action, {
  required Duration timeout,
  String? debugLabel,
}) async {
  try {
    await action.timeout(timeout);
  } catch (e) {
    // ignore: avoid_print
    print('Startup timeout/error${debugLabel != null ? ' ($debugLabel)' : ''}: $e');
  }
}
