// lib/core/models/route_stats.dart
import 'package:milemarker/core/models/stop.dart';

class StateInfo {
  final String stateName;
  final double miles;
  final Duration duration;

  StateInfo({
    required this.stateName,
    required this.miles,
    required this.duration,
  });

  factory StateInfo.fromJson(Map<String, dynamic> json) {
    return StateInfo(
      stateName: json['stateName'] as String,
      miles: (json['miles'] as num).toDouble(),
      duration: Duration(seconds: json['duration'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stateName': stateName,
      'miles': miles,
      'duration': duration.inSeconds,
    };
  }
}

class RouteStats {
  final double totalDistance;
  final Duration totalTime;
  final double averageSpeed;
  final Map<Type, int> stopTypeBreakdown;
  final double estimatedFuelCost;
  final double estimatedTolls;
  final List<Stop> mealStops;
  final List<Stop> fuelStops;
  final List<StateInfo> statesTraversed;

  RouteStats({
    required this.totalDistance,
    required this.totalTime,
    required this.averageSpeed,
    required this.stopTypeBreakdown,
    this.estimatedFuelCost = 0.0,
    this.estimatedTolls = 0.0,
    this.mealStops = const [],
    this.fuelStops = const [],
    this.statesTraversed = const [],
  });

  // Add this getter for compatibility
  Duration get totalDuration => totalTime;

  factory RouteStats.fromJson(Map<String, dynamic> json) {
    return RouteStats(
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalTime: Duration(seconds: json['totalTime'] as int),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      stopTypeBreakdown: Map<Type, int>.from(json['stopTypeBreakdown'] as Map),
      estimatedFuelCost: (json['estimatedFuelCost'] as num?)?.toDouble() ?? 0.0,
      estimatedTolls: (json['estimatedTolls'] as num?)?.toDouble() ?? 0.0,
      mealStops: (json['mealStops'] as List<dynamic>?)
              ?.map((e) => Stop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fuelStops: (json['fuelStops'] as List<dynamic>?)
              ?.map((e) => Stop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statesTraversed: (json['statesTraversed'] as List<dynamic>?)
              ?.map((e) => StateInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalTime': totalTime.inSeconds,
      'averageSpeed': averageSpeed,
      'stopTypeBreakdown': stopTypeBreakdown,
      'estimatedFuelCost': estimatedFuelCost,
      'estimatedTolls': estimatedTolls,
      'mealStops': mealStops.map((e) => e.toJson()).toList(),
      'fuelStops': fuelStops.map((e) => e.toJson()).toList(),
      'statesTraversed': statesTraversed.map((e) => e.toJson()).toList(),
    };
  }
}
