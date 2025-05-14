import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3); // Material Blue
  static const Color secondary = Color(0xFF00BCD4); // Cyan
  static const Color accent = Color(0xFF4CAF50); // Green
  static const Color trackingActive = Color(0xFF4CAF50); // Green
  static const Color trackingStopped = Color(0xFFF44336); // Red
  static const Color trackingPaused = Color(0xFFFFC107); // Amber

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
}

class AppConstants {
  static const String appName = 'MileMarker';
  static const String databaseName = 'milemarker.db';
  static const int databaseVersion = 1;

  // Map settings
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;

  // Location settings
  static const int locationUpdateInterval = 5000; // milliseconds
  static const int fastestLocationUpdateInterval = 2000; // milliseconds
  static const double minDistanceFilter = 5.0; // meters

  // Tracking settings
  static const int autoPauseDuration = 300; // seconds (5 minutes)
  static const double autoPauseSpeed = 0.5; // m/s

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // UI dimensions
  static const double bottomNavHeight = 80.0;
  static const double fabSize = 64.0;
  static const double borderRadius = 20.0;
  static const double minTouchTarget = 48.0;
}

class AppDimensions {
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  static const BorderRadius defaultRadius =
      BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius largeRadius =
      BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius circularRadius =
      BorderRadius.all(Radius.circular(100.0));
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}
