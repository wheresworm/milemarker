import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final List<Leg> legs;
  final String encodedPolyline;
  final Bounds bounds;

  Directions({
    required this.legs,
    required this.encodedPolyline,
    required this.bounds,
  });

  Duration get totalDuration =>
      legs.fold(Duration.zero, (total, leg) => total + leg.duration);

  double get totalDistance =>
      legs.fold(0.0, (total, leg) => total + leg.distance);

  Map<String, dynamic> toMap() => {
        'legs': legs.map((l) => l.toMap()).toList(),
        'encodedPolyline': encodedPolyline,
        'bounds': bounds.toMap(),
      };

  factory Directions.fromGoogleMaps(Map<String, dynamic> json) {
    final route = json['routes'][0];

    return Directions(
      legs: (route['legs'] as List)
          .map((leg) => Leg.fromGoogleMaps(leg))
          .toList(),
      encodedPolyline: route['overview_polyline']['points'],
      bounds: Bounds.fromGoogleMaps(route['bounds']),
    );
  }
}

class Leg {
  final LatLng startLocation;
  final LatLng endLocation;
  final String startAddress;
  final String endAddress;
  final Duration duration;
  final double distance; // miles
  final List<Step> steps;

  Leg({
    required this.startLocation,
    required this.endLocation,
    required this.startAddress,
    required this.endAddress,
    required this.duration,
    required this.distance,
    required this.steps,
  });

  Map<String, dynamic> toMap() => {
        'startLocation': {
          'lat': startLocation.latitude,
          'lng': startLocation.longitude,
        },
        'endLocation': {
          'lat': endLocation.latitude,
          'lng': endLocation.longitude,
        },
        'startAddress': startAddress,
        'endAddress': endAddress,
        'duration': duration.inSeconds,
        'distance': distance,
        'steps': steps.map((s) => s.toMap()).toList(),
      };

  factory Leg.fromGoogleMaps(Map<String, dynamic> json) => Leg(
        startLocation: LatLng(
          json['start_location']['lat'],
          json['start_location']['lng'],
        ),
        endLocation: LatLng(
          json['end_location']['lat'],
          json['end_location']['lng'],
        ),
        startAddress: json['start_address'],
        endAddress: json['end_address'],
        duration: Duration(seconds: json['duration']['value']),
        distance: json['distance']['value'] / 1609.34, // meters to miles
        steps: (json['steps'] as List)
            .map((step) => Step.fromGoogleMaps(step))
            .toList(),
      );
}

class Step {
  final LatLng startLocation;
  final LatLng endLocation;
  final Duration duration;
  final double distance; // miles
  final String htmlInstructions;
  final String? maneuver;
  final String encodedPolyline;

  Step({
    required this.startLocation,
    required this.endLocation,
    required this.duration,
    required this.distance,
    required this.htmlInstructions,
    this.maneuver,
    required this.encodedPolyline,
  });

  String get plainTextInstructions =>
      htmlInstructions.replaceAll(RegExp(r'<[^>]*>'), '');

  Map<String, dynamic> toMap() => {
        'startLocation': {
          'lat': startLocation.latitude,
          'lng': startLocation.longitude,
        },
        'endLocation': {
          'lat': endLocation.latitude,
          'lng': endLocation.longitude,
        },
        'duration': duration.inSeconds,
        'distance': distance,
        'htmlInstructions': htmlInstructions,
        'maneuver': maneuver,
        'encodedPolyline': encodedPolyline,
      };

  factory Step.fromGoogleMaps(Map<String, dynamic> json) => Step(
        startLocation: LatLng(
          json['start_location']['lat'],
          json['start_location']['lng'],
        ),
        endLocation: LatLng(
          json['end_location']['lat'],
          json['end_location']['lng'],
        ),
        duration: Duration(seconds: json['duration']['value']),
        distance: json['distance']['value'] / 1609.34, // meters to miles
        htmlInstructions: json['html_instructions'],
        maneuver: json['maneuver'],
        encodedPolyline: json['polyline']['points'],
      );
}

class Bounds {
  final LatLng northeast;
  final LatLng southwest;

  Bounds({
    required this.northeast,
    required this.southwest,
  });

  Map<String, dynamic> toMap() => {
        'northeast': {
          'lat': northeast.latitude,
          'lng': northeast.longitude,
        },
        'southwest': {
          'lat': southwest.latitude,
          'lng': southwest.longitude,
        },
      };

  factory Bounds.fromGoogleMaps(Map<String, dynamic> json) => Bounds(
        northeast: LatLng(
          json['northeast']['lat'],
          json['northeast']['lng'],
        ),
        southwest: LatLng(
          json['southwest']['lat'],
          json['southwest']['lng'],
        ),
      );
}
