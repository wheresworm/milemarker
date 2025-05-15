// lib/core/services/directions_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/directions.dart';
import '../models/stop.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  late final String _apiKey;

  DirectionsService() {
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  Future<Directions?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<Stop>? waypoints,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    String mode = 'driving',
  }) async {
    try {
      String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$mode&'
          'key=$_apiKey';

      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointString = waypoints
            .map((stop) =>
                '${stop.location.latitude},${stop.location.longitude}')
            .join('|');
        url += '&waypoints=$waypointString';
      }

      // Add avoidance parameters
      List<String> avoid = [];
      if (avoidTolls) avoid.add('tolls');
      if (avoidHighways) avoid.add('highways');
      if (avoidFerries) avoid.add('ferries');
      if (avoid.isNotEmpty) {
        url += '&avoid=${avoid.join('|')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Fix: Use fromGoogleMaps instead of fromJson
          return Directions.fromGoogleMaps(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> optimizeWaypoints({
    required LatLng origin,
    required LatLng destination,
    required List<Stop> waypoints,
  }) async {
    if (waypoints.isEmpty) return null;

    try {
      String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'waypoints=optimize:true|${waypoints.map((stop) => '${stop.location.latitude},${stop.location.longitude}').join('|')}&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return {
            'optimizedOrder': data['routes'][0]['waypoint_order'],
            // Fix: Use fromGoogleMaps instead of fromJson
            'directions': Directions.fromGoogleMaps(data),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error optimizing waypoints: $e');
      return null;
    }
  }
}
