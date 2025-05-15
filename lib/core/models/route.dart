// lib/core/models/route.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';
import 'food_stop.dart';

class Route {
  final String id;
  final String name;
  final LatLng origin;
  final LatLng destination;
  final List<Stop> stops;
  final double distance; // in miles
  final Duration duration;
  final DateTime? departureTime;
  final DateTime createdAt;
  final List<String>? tags;
  final bool isActive;
  final RouteOptimization? optimization;
  final RouteDirections? directions;
  final RouteStats? stats;
  final Map<String, dynamic>? metadata;

  Route({
    String? id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.distance,
    required this.duration,
    this.departureTime,
    DateTime? createdAt,
    this.tags,
    this.isActive = false,
    this.optimization,
    this.directions,
    this.stats,
    this.metadata,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Route copyWith({
    String? id,
    String? name,
    LatLng? origin,
    LatLng? destination,
    List<Stop>? stops,
    double? distance,
    Duration? duration,
    DateTime? departureTime,
    DateTime? createdAt,
    List<String>? tags,
    bool? isActive,
    RouteOptimization? optimization,
    RouteDirections? directions,
    RouteStats? stats,
    Map<String, dynamic>? metadata,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      stops: stops ?? this.stops,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      departureTime: departureTime ?? this.departureTime,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      optimization: optimization ?? this.optimization,
      directions: directions ?? this.directions,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
    );
  }

  LatLng? whereWillIBeAt(DateTime targetTime) {
    if (departureTime == null) return null;

    final elapsed = targetTime.difference(departureTime!);
    if (elapsed.isNegative) return null;

    // Simple linear interpolation based on total duration
    final progress = elapsed.inMinutes / duration.inMinutes;
    if (progress >= 1) return destination;
    if (progress <= 0) return origin;

    // For now, return the nearest stop
    final estimatedStopIndex = (progress * stops.length).floor();
    return stops[estimatedStopIndex.clamp(0, stops.length - 1)].location;
  }

  double distanceProgress(DateTime currentTime) {
    if (departureTime == null) return 0;

    final elapsed = currentTime.difference(departureTime!);
    final progress = elapsed.inMinutes / duration.inMinutes;

    return (progress * distance).clamp(0, distance);
  }

  Map<String, int> categoryBreakdown() {
    final breakdown = <String, int>{};

    for (final stop in stops) {
      if (stop.stopType == StopType.destination) {
        // Fixed: changed from stop.type
        final category = stop.stopType.toString().split('.').last;
        breakdown[category] = (breakdown[category] ?? 0) + 1;
      }
    }

    return breakdown;
  }

  List<MealStop> get mealStops {
    return stops.whereType<FoodStop>().map((stop) {
      final foodStop = stop;
      return MealStop(
        stop: foodStop,
        type: foodStop.mealType.toString().split('.').last,
      );
    }).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'origin_lat': origin.latitude,
      'origin_lng': origin.longitude,
      'destination_lat': destination.latitude,
      'destination_lng': destination.longitude,
      'stops': stops.map((s) => s.toJson()).toList(),
      'distance': distance,
      'duration': duration.inMinutes,
      'departureTime': departureTime?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'tags': tags,
      'isActive': isActive,
      'optimization': optimization?.toMap(),
      'directions': directions?.toMap(),
      'stats': stats?.toMap(),
      'metadata': metadata,
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'],
      name: map['name'],
      origin: LatLng(map['origin_lat'], map['origin_lng']),
      destination: LatLng(map['destination_lat'], map['destination_lng']),
      stops: (map['stops'] as List).map((s) => Stop.fromJson(s)).toList(),
      distance: map['distance'].toDouble(),
      duration: Duration(minutes: map['duration']),
      departureTime: map['departureTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['departureTime'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      isActive: map['isActive'] ?? false,
      optimization: map['optimization'] != null
          ? RouteOptimization.fromMap(map['optimization'])
          : null,
      directions: map['directions'] != null
          ? RouteDirections.fromMap(map['directions'])
          : null,
      stats: map['stats'] != null ? RouteStats.fromMap(map['stats']) : null,
      metadata: map['metadata'],
    );
  }
}

class MealStop {
  final FoodStop stop;
  final String type;

  MealStop({
    required this.stop,
    required this.type,
  });
}

class RouteOptimization {
  final String method;
  final Map<String, dynamic> parameters;
  final DateTime computedAt;

  RouteOptimization({
    required this.method,
    required this.parameters,
    required this.computedAt,
  });

  Map<String, dynamic> toMap() => {
        'method': method,
        'parameters': parameters,
        'computedAt': computedAt.toIso8601String(),
      };

  factory RouteOptimization.fromMap(Map<String, dynamic> map) {
    return RouteOptimization(
      method: map['method'],
      parameters: Map<String, dynamic>.from(map['parameters']),
      computedAt: DateTime.parse(map['computedAt']),
    );
  }
}

class RouteDirections {
  final String polyline;
  final List<String> instructions;
  final Duration estimatedTime;

  RouteDirections({
    required this.polyline,
    required this.instructions,
    required this.estimatedTime,
  });

  Map<String, dynamic> toMap() => {
        'polyline': polyline,
        'instructions': instructions,
        'estimatedTime': estimatedTime.inMinutes,
      };

  factory RouteDirections.fromMap(Map<String, dynamic> map) {
    return RouteDirections(
      polyline: map['polyline'],
      instructions: List<String>.from(map['instructions']),
      estimatedTime: Duration(minutes: map['estimatedTime']),
    );
  }
}

class RouteStats {
  final double totalDistance;
  final Duration totalTime;
  final double averageSpeed;
  final int numberOfStops;
  final Map<String, int> stopTypeBreakdown;

  RouteStats({
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.numberOfStops,
    required this.stopTypeBreakdown,
  });

  Map<String, dynamic> toMap() => {
        'totalDistance': totalDistance,
        'totalTime': totalTime.inMinutes,
        'averageSpeed': averageSpeed,
        'numberOfStops': numberOfStops,
        'stopTypeBreakdown': stopTypeBreakdown,
      };

  factory RouteStats.fromMap(Map<String, dynamic> map) {
    return RouteStats(
      totalDistance: map['totalDistance'].toDouble(),
      totalTime: Duration(minutes: map['totalTime']),
      averageSpeed: map['averageSpeed'].toDouble(),
      numberOfStops: map['numberOfStops'],
      stopTypeBreakdown: Map<String, int>.from(map['stopTypeBreakdown']),
    );
  }
}
