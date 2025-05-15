import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/directions_result.dart';
import '../models/stop.dart';
import '../utils/polyline_utils.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final String apiKey;

  DirectionsService({required this.apiKey});

  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<Stop>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    DateTime? departureTime,
  }) async {
    // Simulated API response for development
    // In production, you would make an actual HTTP request here

    try {
      // Calculate direct distance
      final distance = _calculateDistance(origin, destination);

      // Estimate duration based on average speed
      final averageSpeedKmh = 60.0;
      final durationHours = distance / averageSpeedKmh;
      final duration = Duration(minutes: (durationHours * 60).round());

      // Generate a simple polyline
      List<LatLng> polylinePoints = [];

      if (waypoints != null && waypoints.isNotEmpty) {
        // Add origin
        polylinePoints.add(origin);

        // Add waypoints
        for (final waypoint in waypoints) {
          polylinePoints.add(waypoint.location);
        }

        // Add destination
        polylinePoints.add(destination);
      } else {
        // Simple direct line
        polylinePoints = [origin, destination];
      }

      // Encode polyline
      final encodedPolyline = PolylineUtils.encode(polylinePoints);

      return DirectionsResult(
        polylinePoints: polylinePoints,
        totalDistance: distance * 1000, // Convert to meters
        totalDuration: duration,
        encodedPolyline: encodedPolyline,
      );
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  // Haversine formula to calculate distance between two points
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1Rad = start.latitude * (math.pi / 180);
    final lat2Rad = end.latitude * (math.pi / 180);
    final deltaLatRad = (end.latitude - start.latitude) * (math.pi / 180);
    final deltaLngRad = (end.longitude - start.longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Generate intermediate points for smoother polylines
  List<LatLng> _generateIntermediatePoints(
      LatLng start, LatLng end, int numPoints) {
    final points = <LatLng>[];

    for (int i = 0; i <= numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }
}
