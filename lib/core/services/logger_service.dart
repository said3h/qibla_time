import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static const String _prefix = '[QiblaTime]';
  
  // Configuración
  static LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
  
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Filtrar por nivel mínimo
    if (level.index < minimumLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final output = '$_prefix [$timestamp] $levelStr: $message';
    
    debugPrint(output);
    
    if (error != null) {
      debugPrint('$_prefix   └─ Error: $error');
    }
    
    if (stackTrace != null) {
      debugPrint('$_prefix   └─ Stack trace:\n$stackTrace');
    }
  }
}
