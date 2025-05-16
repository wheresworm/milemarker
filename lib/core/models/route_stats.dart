// lib/core/models/route_stats.dart

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
  final double estimatedFuelCost;
  final double estimatedFuelUsage;
  final int numberOfStops;

  RouteStats({
    required this.totalDistance,
    required this.totalTime,
    required this.estimatedFuelCost,
    required this.estimatedFuelUsage,
    required this.numberOfStops,
  });

  factory RouteStats.fromJson(Map<String, dynamic> json) {
    return RouteStats(
      totalDistance: json['totalDistance'].toDouble(),
      totalTime: Duration(seconds: json['totalTime']),
      estimatedFuelCost: json['estimatedFuelCost'].toDouble(),
      estimatedFuelUsage: json['estimatedFuelUsage'].toDouble(),
      numberOfStops: json['numberOfStops'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalTime': totalTime.inSeconds,
      'estimatedFuelCost': estimatedFuelCost,
      'estimatedFuelUsage': estimatedFuelUsage,
      'numberOfStops': numberOfStops,
    };
  }
}
