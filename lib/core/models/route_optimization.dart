// lib/core/models/route_optimization.dart
import 'package:milemarker/core/models/user_route.dart';
import 'package:milemarker/core/models/route_stats.dart';

enum OptimizationCriteria {
  fastest,
  shortest,
  fuelEfficient,
  scenic,
  balanced,
}

class RouteOptimization {
  final OptimizationCriteria criteria;
  final UserRoute optimizedRoute;
  final RouteStats currentStats;
  final RouteStats optimizedStats;
  final List<String> recommendations;

  RouteOptimization({
    required this.criteria,
    required this.optimizedRoute,
    required this.currentStats,
    required this.optimizedStats,
    this.recommendations = const [],
  });

  // Add these getters for backward compatibility
  OptimizationCriteria get fastest => OptimizationCriteria.fastest;
  OptimizationCriteria get fuelEfficient => OptimizationCriteria.fuelEfficient;
  OptimizationCriteria get scenic => OptimizationCriteria.scenic;

  double get timeSaved {
    final saved =
        currentStats.totalTime.inMinutes - optimizedStats.totalTime.inMinutes;
    return saved > 0 ? saved.toDouble() : 0.0;
  }

  double get distanceSaved {
    final saved = currentStats.totalDistance - optimizedStats.totalDistance;
    return saved > 0 ? saved : 0.0;
  }

  double get fuelSaved {
    final saved =
        currentStats.estimatedFuelCost - optimizedStats.estimatedFuelCost;
    return saved > 0 ? saved : 0.0;
  }

  factory RouteOptimization.fromJson(Map<String, dynamic> json) {
    return RouteOptimization(
      criteria: OptimizationCriteria.values.firstWhere(
        (c) => c.toString() == json['criteria'],
      ),
      optimizedRoute: UserRoute.fromJson(json['optimizedRoute']),
      currentStats: RouteStats.fromJson(json['currentStats']),
      optimizedStats: RouteStats.fromJson(json['optimizedStats']),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criteria': criteria.toString(),
      'optimizedRoute': optimizedRoute.toJson(),
      'currentStats': currentStats.toJson(),
      'optimizedStats': optimizedStats.toJson(),
      'recommendations': recommendations,
    };
  }
}
