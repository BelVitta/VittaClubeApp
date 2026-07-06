import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  const AppLogger._();

  static void debug(
    String message, {
    String name = 'VitaClube',
    Map<String, Object?> context = const {},
  }) {
    _log(LogLevel.debug, message, name: name, context: context);
  }

  static void info(
    String message, {
    String name = 'VitaClube',
    Map<String, Object?> context = const {},
  }) {
    _log(LogLevel.info, message, name: name, context: context);
  }

  static void warning(
    String message, {
    String name = 'VitaClube',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _log(
      LogLevel.warning,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void error(
    String message, {
    String name = 'VitaClube',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _log(
      LogLevel.error,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (level == LogLevel.debug && !kDebugMode) return;

    final logMessage = context.isEmpty
        ? '[${level.name}] $message'
        : '[${level.name}] $message | ${_formatContext(context)}';

    developer.log(
      logMessage,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _developerLevel(level),
    );

    if (kDebugMode) {
      final errorSuffix = error == null ? '' : ' | error=$error';
      debugPrint('$name: $logMessage$errorSuffix');
    }
  }

  static int _developerLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  static String _formatContext(Map<String, Object?> context) {
    return context.entries
        .map((entry) => '${entry.key}=${_safeValue(entry.value)}')
        .join(' ');
  }

  static String _safeValue(Object? value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value.toString();
    return '"${value.toString()}"';
  }
}
