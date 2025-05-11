// lib/utils/logger.dart

import 'package:logging/logging.dart';

/// Centralized application logger.
class AppLogger {
  static final Logger _logger = Logger('MileMarker');

  /// Call once at app startup (e.g. in main()).
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final time = record.time.toIso8601String();
      print(
        '${record.level.name}: $time: '
        '${record.loggerName}: ${record.message}',
      );
    });
  }

  static void fine(String msg) => _logger.fine(msg);
  static void info(String msg) => _logger.info(msg);
  static void warning(String msg) => _logger.warning(msg);
  static void severe(String msg) => _logger.severe(msg);
}
