// lib/core/models/location_point.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPoint {
  final LatLng position;
  final DateTime timestamp;
  final double? speed;
  final double? altitude;
  final double? accuracy;

  LocationPoint({
    required this.position,
    required this.timestamp,
    this.speed,
    this.altitude,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      position: LatLng(map['latitude'], map['longitude']),
      timestamp: DateTime.parse(map['timestamp']),
      speed: map['speed'],
      altitude: map['altitude'],
      accuracy: map['accuracy'],
    );
  }
}
