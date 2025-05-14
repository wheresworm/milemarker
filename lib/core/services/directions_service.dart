import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  final http.Client _httpClient = http.Client();

  Future<Directions> getDirections({
    LatLng? origin,
    LatLng? destination,
    List<LatLng>? waypoints,
    DateTime? departureTime,
  }) async {
    if (_apiKey == null) {
      throw Exception('Google Maps API key not found');
    }

    // If waypoints are provided but no origin/destination, use first and last
    final actualOrigin = origin ?? (waypoints?.first ?? throw ArgumentError('Origin required'));
    final actualDestination = destination ?? (waypoints?.last ?? throw ArgumentError('Destination required'));
    
    // Extract intermediate waypoints
    List<LatLng> intermediateWaypoints = [];
    if (waypoints != null && waypoints.length > 2) {
      intermediateWaypoints = waypoints.sublist(1, waypoints.length - 1);
    }

    String waypointsParam = '';
    if (intermediateWaypoints.isNotEmpty) {
      final waypointStrings = intermediateWaypoints
          .map((w) => '${w.latitude},${w.longitude}')
          .join('|');
      waypointsParam = '&waypoints=optimize:true|$waypointStrings';
    }

    final departureTimeParam = departureTime != null
        ? '&departure_time=${departureTime.millisecondsSinceEpoch ~/ 1000}'
        : '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${actualOrigin.latitude},${actualOrigin.longitude}'
      '&destination=${actualDestination.latitude},${actualDestination.longitude}'
      '$waypointsParam'
      '&mode=driving'
      '$departureTimeParam'
      '&key=$_apiKey',
    );

    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        return Directions.fromJson(data['routes'][0]);
      } else {
        throw Exception('No routes found: ${data['status']}');
      }
    } else {
      throw Exception('Failed to get directions: ${response.statusCode}');
    }
  }
}

class Directions {
  final List<LatLng> polylinePoints;
  final double totalDistance; // in miles
  final Duration totalDuration;
  final String? summary;
  final List<DirectionStep> steps;

  Directions({
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    this.summary,
    required this.steps,
  });

  factory Directions.fromJson(Map<String, dynamic> json) {
    final overviewPolyline = json['overview_polyline']['points'];
    final polylinePoints = _decodePolyline(overviewPolyline);

    final legs = json['legs'] as List;
    double totalDistanceMeters = 0;
    int totalDurationSeconds = 0;
    List<DirectionStep> allSteps = [];

    for (final leg in legs) {
      totalDistanceMeters += leg['distance']['value'];
      totalDurationSeconds += leg['duration']['value'];
      
      final steps = leg['steps'] as List;
      allSteps.addAll(steps.map((s) => DirectionStep.fromJson(s)));
    }

    return Directions(
      polylinePoints: polylinePoints,
      totalDistance: totalDistanceMeters / 1609.344, // Convert to miles
      totalDuration: Duration(seconds: totalDurationSeconds),
      summary: json['summary'],
      steps: allSteps,
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

class DirectionStep {
  final LatLng startLocation;
  final LatLng endLocation;
  final String instructions;
  final double distance; // in miles
  final Duration duration;
  final String travelMode;

  DirectionStep({
    required this.startLocation,
    required this.endLocation,
    required this.instructions,
    required this.distance,
    required this.duration,
    required this.travelMode,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    final start = json['start_location'];
    final end = json['end_location'];
    
    return DirectionStep(
      startLocation: LatLng(start['lat'], start['lng']),
      endLocation: LatLng(end['lat'], end['lng']),
      instructions: json['html_instructions'],
      distance: json['distance']['value'] / 1609.344, // Convert to miles
      duration: Duration(seconds: json['duration']['value']),
      travelMode: json['travel_mode'],
    );
  }
}