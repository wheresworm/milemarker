import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_data.dart';
import '../utils/logger.dart';

class DirectionsService {
  final String apiKey;
  final http.Client client;

  // Cache for directions results
  final Map<String, RouteData> _directionsCache = {};

  DirectionsService({String? apiKey, http.Client? client})
    : apiKey = apiKey ?? dotenv.env['GOOGLE_API_KEY'] ?? '',
      client = client ?? http.Client();

  // Generate a cache key based on origin, destination and waypoints
  String _generateCacheKey(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints,
    DateTime? departureTime,
  ) {
    final waypointsString = waypoints
        .map((w) => '${w.latitude},${w.longitude}')
        .join('|');

    final timeString =
        departureTime?.millisecondsSinceEpoch.toString() ?? 'now';

    return '${origin.latitude},${origin.longitude}|'
        '${destination.latitude},${destination.longitude}|'
        '$waypointsString|$timeString';
  }

  // Get directions
  Future<RouteData?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
    DateTime? departureTime,
  }) async {
    // Disable cache for departure time requests to ensure we get fresh traffic data
    final cacheKey = _generateCacheKey(
      origin,
      destination,
      waypoints,
      departureTime,
    );

    // Only use cache if we're not using departure time
    if (departureTime == null && _directionsCache.containsKey(cacheKey)) {
      AppLogger.info('DirectionsService: Using cached directions');
      return _directionsCache[cacheKey];
    }

    final baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

    final originParam = '${origin.latitude},${origin.longitude}';
    final destinationParam = '${destination.latitude},${destination.longitude}';

    // Fix the waypoints format
    String waypointsParam = '';
    if (waypoints.isNotEmpty) {
      waypointsParam = '&waypoints=';
      for (int i = 0; i < waypoints.length; i++) {
        if (i > 0) waypointsParam += '|';
        waypointsParam += '${waypoints[i].latitude},${waypoints[i].longitude}';
      }
    }

    // Make sure departure time is in the future
    String trafficParams = '';
    if (departureTime != null) {
      final now = DateTime.now();
      // If the specified time is in the past, use the current time plus 5 minutes
      final effectiveDepartureTime =
          departureTime.isBefore(now)
              ? now.add(const Duration(minutes: 5))
              : departureTime;

      // Add both departure_time and traffic_model parameters
      trafficParams =
          '&departure_time=${effectiveDepartureTime.millisecondsSinceEpoch ~/ 1000}'
          '&traffic_model=best_guess';
    }

    final url = Uri.parse(
      '$baseUrl?origin=$originParam'
      '&destination=$destinationParam'
      '$waypointsParam'
      '&mode=driving'
      '$trafficParams'
      '&key=$apiKey',
    );

    AppLogger.info('DirectionsService: Fetching directions from: $url');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the full response for debugging
        AppLogger.info('DirectionsService: Response received');

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;

          if (routes.isNotEmpty) {
            final route = routes.first;
            final legs = route['legs'] as List;

            int totalDurationSeconds = 0;
            int totalDistanceMeters = 0;
            int? durationInTrafficSeconds;

            for (final leg in legs) {
              totalDurationSeconds += leg['duration']['value'] as int;
              totalDistanceMeters += leg['distance']['value'] as int;

              // Check if duration_in_traffic is present
              if (leg.containsKey('duration_in_traffic')) {
                final trafficDuration =
                    leg['duration_in_traffic']['value'] as int;
                durationInTrafficSeconds =
                    (durationInTrafficSeconds ?? 0) + trafficDuration;
                AppLogger.info(
                  'DirectionsService: Found traffic duration: ${leg['duration_in_traffic']['text']}',
                );
              }
            }

            // Use traffic duration if available
            final effectiveDurationSeconds =
                durationInTrafficSeconds ?? totalDurationSeconds;

            final polyline = route['overview_polyline']['points'] as String;

            final routeData = RouteData(
              polyline: polyline,
              durationInSeconds: effectiveDurationSeconds,
              distanceInMeters: totalDistanceMeters,
              legs: legs.map((leg) => _parseLeg(leg)).toList(),
            );

            // Cache the result only if not using departure time
            if (departureTime == null) {
              _directionsCache[cacheKey] = routeData;
            }

            AppLogger.info(
              'DirectionsService: Successfully fetched directions with duration: ${routeData.formattedDuration}',
            );
            return routeData;
          }
        } else {
          AppLogger.warning(
            'DirectionsService: API returned status: ${data['status']}',
          );
          if (data.containsKey('error_message')) {
            AppLogger.warning(
              'DirectionsService: Error message: ${data['error_message']}',
            );
          }
        }
      } else {
        AppLogger.severe(
          'DirectionsService: HTTP error ${response.statusCode}',
        );
        AppLogger.severe('DirectionsService: Response body: ${response.body}');
      }

      return null;
    } catch (e) {
      AppLogger.severe('DirectionsService: Error fetching directions: $e');
      return null;
    }
  }

  // Parse a leg from the directions response
  RouteLeg _parseLeg(Map<String, dynamic> legData) {
    int durationValue = legData['duration']['value'];

    // Use duration_in_traffic if available
    if (legData.containsKey('duration_in_traffic')) {
      durationValue = legData['duration_in_traffic']['value'];
    }

    return RouteLeg(
      startAddress: legData['start_address'],
      endAddress: legData['end_address'],
      durationInSeconds: durationValue,
      distanceInMeters: legData['distance']['value'],
      startLocation: LatLng(
        legData['start_location']['lat'],
        legData['start_location']['lng'],
      ),
      endLocation: LatLng(
        legData['end_location']['lat'],
        legData['end_location']['lng'],
      ),
    );
  }

  // Clear cache
  void clearCache() {
    _directionsCache.clear();
  }
}
