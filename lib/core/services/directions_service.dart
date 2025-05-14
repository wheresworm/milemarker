import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/directions.dart';
import '../config/api_config.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  final String apiKey = ApiConfig.googleApiKey;

  DirectionsService();

  Future<Directions> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
    bool avoidTolls = false,
    bool avoidHighways = false,
    DateTime? departureTime,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        if (waypoints.isNotEmpty)
          'waypoints':
              waypoints.map((w) => '${w.latitude},${w.longitude}').join('|'),
        'mode': 'driving',
        'avoid': [
          if (avoidTolls) 'tolls',
          if (avoidHighways) 'highways',
        ].join('|'),
        if (departureTime != null)
          'departure_time': departureTime.millisecondsSinceEpoch.toString(),
        'units': 'imperial',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Directions API error: ${json['status']}');
    }

    return Directions.fromGoogleMaps(json);
  }

  // Get directions with multiple alternative routes
  Future<List<Directions>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        if (waypoints.isNotEmpty)
          'waypoints':
              waypoints.map((w) => '${w.latitude},${w.longitude}').join('|'),
        'mode': 'driving',
        'alternatives': 'true',
        'units': 'imperial',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Directions API error: ${json['status']}');
    }

    return (json['routes'] as List)
        .map((route) => Directions.fromGoogleMaps({
              'routes': [route]
            }))
        .toList();
  }

  // Calculate optimal waypoint order
  Future<List<int>> optimizeWaypoints({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'waypoints':
            'optimize:true|${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}',
        'mode': 'driving',
        'units': 'imperial',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to optimize waypoints: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Directions API error: ${json['status']}');
    }

    return (json['routes'][0]['waypoint_order'] as List)
        .map((index) => index as int)
        .toList();
  }
}
