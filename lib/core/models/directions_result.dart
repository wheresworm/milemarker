// lib/core/models/directions_result.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final double totalDistance;
  final Duration totalDuration;
  final String encodedPolyline;

  DirectionsResult({
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.encodedPolyline,
  });
}
