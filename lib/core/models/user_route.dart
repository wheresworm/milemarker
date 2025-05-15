// lib/core/models/user_route.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';

class UserRoute {
  final String id;
  final String title; // Changed from 'name' to 'title'
  final String startPoint; // Added
  final String endPoint; // Added
  final List<Stop> stops;
  final double? distance; // Changed from totalDistance and made nullable
  final Duration? duration; // Changed from totalDuration and made nullable
  final List<LatLng> polylinePoints;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final DateTime createdAt;
  final DateTime? lastUsed; // Changed from lastModified
  final int useCount; // Added
  final String? notes; // Added
  final RouteType type;
  final bool isActive;

  UserRoute({
    String? id,
    required this.title,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    this.distance,
    this.duration,
    List<LatLng>? polylinePoints,
    this.departureTime,
    this.arrivalTime,
    DateTime? createdAt,
    this.lastUsed,
    this.useCount = 0,
    this.notes,
    this.type = RouteType.custom,
    this.isActive = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        polylinePoints = polylinePoints ?? [];

  // Add getters for backward compatibility
  String get name => title;
  double get totalDistance => distance ?? 0.0;
  Duration get totalDuration => duration ?? Duration.zero;

  UserRoute copyWith({
    String? id,
    String? title,
    String? startPoint,
    String? endPoint,
    List<Stop>? stops,
    double? distance,
    Duration? duration,
    List<LatLng>? polylinePoints,
    DateTime? departureTime,
    DateTime? arrivalTime,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? useCount,
    String? notes,
    RouteType? type,
    bool? isActive,
  }) {
    return UserRoute(
      id: id ?? this.id,
      title: title ?? this.title,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      stops: stops ?? this.stops,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startPoint': startPoint,
        'endPoint': endPoint,
        'stops': stops.map((s) => s.toJson()).toList(),
        'distance': distance,
        'duration': duration?.inSeconds,
        'polylinePoints': polylinePoints
            .map((p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                })
            .toList(),
        'departureTime': departureTime?.toIso8601String(),
        'arrivalTime': arrivalTime?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastUsed': lastUsed?.toIso8601String(),
        'useCount': useCount,
        'notes': notes,
        'type': type.toString().split('.').last,
        'isActive': isActive,
      };

  factory UserRoute.fromJson(Map<String, dynamic> json) {
    return UserRoute(
      id: json['id'],
      title: json['title'] ??
          json['name'], // Support both for backward compatibility
      startPoint: json['startPoint'] ?? '',
      endPoint: json['endPoint'] ?? '',
      stops: (json['stops'] as List).map((s) => Stop.fromJson(s)).toList(),
      distance:
          json['distance']?.toDouble() ?? json['totalDistance']?.toDouble(),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : json['totalDuration'] != null
              ? Duration(minutes: json['totalDuration'])
              : null,
      polylinePoints: json['polylinePoints'] != null
          ? (json['polylinePoints'] as List)
              .map((p) => LatLng(p['lat'], p['lng']))
              .toList()
          : [],
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'])
          : json['lastModified'] != null
              ? DateTime.parse(json['lastModified'])
              : null,
      useCount: json['useCount'] ?? 0,
      notes: json['notes'],
      type: RouteType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => RouteType.custom,
      ),
      isActive: json['isActive'] ?? false,
    );
  }
}

enum RouteType { custom, daily, scenic, fastest }
