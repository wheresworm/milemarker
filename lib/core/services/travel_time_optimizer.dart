import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'directions_service.dart';
import '../utils/logger.dart';
import '../../data/models/route_data.dart';

class TravelTimeOptimizer {
  final DirectionsService _directionsService;

  TravelTimeOptimizer({DirectionsService? directionsService})
    : _directionsService = directionsService ?? DirectionsService();

  // Calculate travel times for different departure times
  Future<Map<DateTime, RouteData?>> calculateTimesForRange({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    required DateTime baseTime,
    Duration range = const Duration(hours: 24),
    Duration step = const Duration(hours: 3),
  }) async {
    final result = <DateTime, RouteData?>{};

    // Calculate how many steps we need
    final steps = range.inSeconds ~/ step.inSeconds;

    AppLogger.info(
      'TravelTimeOptimizer: Calculating travel times for $steps departure options',
    );

    for (int i = 0; i <= steps; i++) {
      final departureTime = baseTime.add(step * i);

      // Get route data for this departure time
      final routeData = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        departureTime: departureTime,
      );

      result[departureTime] = routeData;

      if (routeData != null) {
        AppLogger.info(
          'TravelTimeOptimizer: Departure at $departureTime: ${routeData.durationInSeconds} seconds',
        );
      } else {
        AppLogger.warning(
          'TravelTimeOptimizer: Failed to get route data for departure at $departureTime',
        );
      }
    }

    return result;
  }

  // Find the optimal departure time
  Future<DateTime?> findOptimalDepartureTime({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    required DateTime baseTime,
    Duration range = const Duration(hours: 24),
    Duration step = const Duration(hours: 3),
  }) async {
    final times = await calculateTimesForRange(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      baseTime: baseTime,
      range: range,
      step: step,
    );

    if (times.isEmpty) return null;

    // Find the departure time with the shortest duration
    DateTime? optimalTime;
    int? shortestDuration;

    times.forEach((departureTime, routeData) {
      if (routeData != null) {
        if (shortestDuration == null ||
            routeData.durationInSeconds < shortestDuration!) {
          shortestDuration = routeData.durationInSeconds;
          optimalTime = departureTime;
        }
      }
    });

    return optimalTime;
  }
}
