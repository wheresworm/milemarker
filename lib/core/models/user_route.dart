import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';

class UserRoute {
  final String id;
  final String name;
  final List<Stop> stops;
  final double totalDistance; // in miles
  final Duration totalDuration;
  final List<LatLng> polylinePoints;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final DateTime createdAt;
  final DateTime? lastModified;
  final RouteType type;
  final bool isActive;

  UserRoute({
    String? id,
    required this.name,
    required this.stops,
    required this.totalDistance,
    required this.totalDuration,
    required this.polylinePoints,
    this.departureTime,
    this.arrivalTime,
    DateTime? createdAt,
    this.lastModified,
    this.type = RouteType.custom,
    this.isActive = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  UserRoute copyWith({
    String? id,
    String? name,
    List<Stop>? stops,
    double? totalDistance,
    Duration? totalDuration,
    List<LatLng>? polylinePoints,
    DateTime? departureTime,
    DateTime? arrivalTime,
    DateTime? createdAt,
    DateTime? lastModified,
    RouteType? type,
    bool? isActive,
  }) {
    return UserRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      stops: stops ?? this.stops,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stops': stops.map((s) => s.toJson()).toList(),
        'totalDistance': totalDistance,
        'totalDuration': totalDuration.inMinutes,
        'polylinePoints': polylinePoints
            .map((p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                })
            .toList(),
        'departureTime': departureTime?.toIso8601String(),
        'arrivalTime': arrivalTime?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
        'type': type.toString().split('.').last,
        'isActive': isActive,
      };

  factory UserRoute.fromJson(Map<String, dynamic> json) {
    return UserRoute(
      id: json['id'],
      name: json['name'],
      stops: (json['stops'] as List).map((s) => Stop.fromJson(s)).toList(),
      totalDistance: json['totalDistance'].toDouble(),
      totalDuration: Duration(minutes: json['totalDuration']),
      polylinePoints: (json['polylinePoints'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
      type: RouteType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => RouteType.custom,
      ),
      isActive: json['isActive'] ?? false,
    );
  }
}

enum RouteType { custom, daily, scenic, fastest }
