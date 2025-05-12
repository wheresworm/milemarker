import 'package:flutter/foundation.dart';

// Log levels
enum LogLevel {
  severe, // 0: Only show severe errors
  warning, // 1: Show warnings and above
  info, // 2: Show info and above (default)
  fine, // 3: Show fine details and above
  finer, // 4: Show more details
  finest, // 5: Show all details
}

class AppLogger {
  static const String _tag = "MileMarker";
  static bool _initialized = false;
  static LogLevel _logLevel = LogLevel.info;

  // Initialize logger with a specific log level
  static void init({LogLevel level = LogLevel.info}) {
    _logLevel = level;
    _initialized = true;
    info("Logger initialized with level: $_logLevel");
  }

  // Log a severe error
  static void severe(String message) {
    _log(LogLevel.severe, message);
  }

  // Log a warning
  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  // Log information
  static void info(String message) {
    _log(LogLevel.info, message);
  }

  // Log fine details
  static void fine(String message) {
    _log(LogLevel.fine, message);
  }

  // Internal logging method
  static void _log(LogLevel level, String message) {
    if (!_initialized) {
      init(); // Auto-initialize with default settings
    }

    if (level.index <= _logLevel.index) {
      if (kDebugMode) {
        print("${_getLevelPrefix(level)} $_tag: $message");
      }
    }
  }

  // Get prefix for log level
  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.severe:
        return "🔴 SEVERE";
      case LogLevel.warning:
        return "🟠 WARNING";
      case LogLevel.info:
        return "🔵 INFO";
      case LogLevel.fine:
        return "🟢 FINE";
      case LogLevel.finer:
        return "🟢 FINER";
      case LogLevel.finest:
        return "🟢 FINEST";
      default:
        return "🔵 LOG";
    }
  }
}
