import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // No method calls in logs
      errorMethodCount: 8,
      lineLength: 120, // Wide logs for better readability
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static void _log(
      void Function(dynamic) logFunction,
      dynamic message, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    if (kDebugMode) {
      if (error != null) {
        _logger.e(
          "🚨 ERROR: $message",
          error: error,
          stackTrace: stackTrace ?? StackTrace.current,
        );
      } else {
        logFunction(message);
      }
    }
  }

  static void i(dynamic message) => _log(_logger.i, message);
  static void d(dynamic message) => _log(_logger.d, message);
  static void w(dynamic message) => _log(_logger.w, message);
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _log(_logger.e, message, error: error, stackTrace: stackTrace);
  static void t(dynamic message) => _log(_logger.t, message);
}