import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  final String polyline;
  final int durationInSeconds;
  final int distanceInMeters;
  final List<RouteLeg> legs;

  RouteData({
    required this.polyline,
    required this.durationInSeconds,
    required this.distanceInMeters,
    required this.legs,
  });

  // Helper to get duration as a Duration object
  Duration get duration => Duration(seconds: durationInSeconds);

  // Helper to get distance in miles
  double get distanceInMiles => distanceInMeters / 1609.34;

  // Helper to get a formatted distance string
  String get formattedDistance {
    final miles = distanceInMiles;
    if (miles >= 1.0) {
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      final feet = (miles * 5280).toInt();
      return '$feet ft';
    }
  }

  // Helper to get a formatted duration string
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}

class RouteLeg {
  final String startAddress;
  final String endAddress;
  final int durationInSeconds;
  final int distanceInMeters;
  final LatLng startLocation;
  final LatLng endLocation;

  RouteLeg({
    required this.startAddress,
    required this.endAddress,
    required this.durationInSeconds,
    required this.distanceInMeters,
    required this.startLocation,
    required this.endLocation,
  });

  // Helper to get duration as a Duration object
  Duration get duration => Duration(seconds: durationInSeconds);

  // Helper to get distance in miles
  double get distanceInMiles => distanceInMeters / 1609.34;
}
