// lib/core/models/tracking_data.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'trip.dart';
import 'user_route.dart';

class TrackingData {
  final String id;
  final String routeId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final TripStatus status;
  final DateTime lastUpdated;
  final double distance; // in kilometers
  final Duration duration;
  final UserRoute? route;
  final double averageSpeed; // in km/h
  final double maxSpeed; // in km/h
  final List<LatLng>? trackPoints;

  TrackingData({
    required this.id,
    required this.routeId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.lastUpdated,
    required this.distance,
    required this.duration,
    this.route,
    required this.averageSpeed,
    required this.maxSpeed,
    this.trackPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated.toIso8601String(),
      'distance': distance,
      'duration': duration.inSeconds,
      'route': route?.toJson(),
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'trackPoints': trackPoints
          ?.map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              })
          .toList(),
    };
  }

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      id: json['id'],
      routeId: json['routeId'],
      title: json['title'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: TripStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
      ),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      distance: json['distance'].toDouble(),
      duration: Duration(seconds: json['duration']),
      route: json['route'] != null ? UserRoute.fromJson(json['route']) : null,
      averageSpeed: json['averageSpeed'].toDouble(),
      maxSpeed: json['maxSpeed'].toDouble(),
      trackPoints: json['trackPoints'] != null
          ? (json['trackPoints'] as List)
              .map((p) => LatLng(
                    p['latitude'],
                    p['longitude'],
                  ))
              .toList()
          : null,
    );
  }
}
