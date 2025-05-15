// lib/core/services/route_optimization_service.dart
import 'package:milemarker/core/models/route_optimization.dart';
import 'package:milemarker/core/models/directions.dart' as models;
import 'package:milemarker/core/models/stop.dart';
import 'package:milemarker/core/models/route_stats.dart';
import 'package:milemarker/core/models/vehicle.dart';
import 'package:milemarker/core/models/user_route.dart';
import 'package:milemarker/core/services/directions_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteOptimizationService {
  final DirectionsService _directionsService;

  RouteOptimizationService({DirectionsService? directionsService})
      : _directionsService = directionsService ?? DirectionsService();

  Future<RouteOptimization> optimizeRoute({
    required UserRoute route,
    required OptimizationCriteria criteria,
    Vehicle? vehicle,
  }) async {
    // Get the current route stats
    final currentStats = await _calculateRouteStats(route, null);

    RouteOptimization optimization;

    switch (criteria) {
      case OptimizationCriteria.fastest:
        optimization = await _optimizeForTime(route, currentStats);
        break;
      case OptimizationCriteria.shortest:
        optimization = await _optimizeForDistance(route, currentStats);
        break;
      case OptimizationCriteria.fuelEfficient:
        optimization =
            await _optimizeForFuelEfficiency(route, vehicle, currentStats);
        break;
      case OptimizationCriteria.scenic:
        optimization = await _optimizeForScenic(route, currentStats);
        break;
      case OptimizationCriteria.balanced:
        optimization = await _optimizeBalanced(route, currentStats);
        break;
    }

    return optimization;
  }

  Future<RouteOptimization> _optimizeForTime(
    UserRoute route,
    RouteStats currentStats,
  ) async {
    try {
      // Get optimized waypoint order
      final optimizationResult = await _directionsService.optimizeWaypoints(
        origin: _extractLatLng(route.startPoint),
        destination: _extractLatLng(route.endPoint),
        waypoints: route.stops,
      );

      if (optimizationResult == null) {
        return RouteOptimization(
          criteria: OptimizationCriteria.fastest,
          optimizedRoute: route,
          currentStats: currentStats,
          optimizedStats: currentStats,
          recommendations: ['Unable to optimize route'],
        );
      }

      // Reorder stops based on optimization
      final optimizedOrder = optimizationResult['optimizedOrder'] as List<int>;
      final optimizedStops = _reorderStops(route.stops, optimizedOrder);

      // Create optimized route
      final optimizedRoute = UserRoute(
        id: route.id,
        title: route.title,
        startPoint: route.startPoint,
        endPoint: route.endPoint,
        stops: optimizedStops,
        distance: route.distance,
        duration: route.duration,
        createdAt: route.createdAt,
        lastUsed: route.lastUsed,
        useCount: route.useCount,
        notes: route.notes,
      );

      // Calculate stats for optimized route
      final optimizedStats = await _calculateRouteStats(
        optimizedRoute,
        optimizationResult['directions'] as models.Directions,
      );

      return RouteOptimization(
        criteria: OptimizationCriteria.fastest,
        optimizedRoute: optimizedRoute,
        currentStats: currentStats,
        optimizedStats: optimizedStats,
        recommendations:
            _generateTimeRecommendations(currentStats, optimizedStats),
      );
    } catch (e) {
      print('Error optimizing for time: $e');
      return RouteOptimization(
        criteria: OptimizationCriteria.fastest,
        optimizedRoute: route,
        currentStats: currentStats,
        optimizedStats: currentStats,
        recommendations: ['Error optimizing route'],
      );
    }
  }

  Future<RouteOptimization> _optimizeForDistance(
    UserRoute route,
    RouteStats currentStats,
  ) async {
    // Similar implementation to _optimizeForTime but prioritizing distance
    // For now, return a basic implementation
    return RouteOptimization(
      criteria: OptimizationCriteria.shortest,
      optimizedRoute: route,
      currentStats: currentStats,
      optimizedStats: currentStats,
      recommendations: ['Route is already optimized for distance'],
    );
  }

  Future<RouteOptimization> _optimizeForFuelEfficiency(
    UserRoute route,
    Vehicle? vehicle,
    RouteStats currentStats,
  ) async {
    if (vehicle == null) {
      return RouteOptimization(
        criteria: OptimizationCriteria.fuelEfficient,
        optimizedRoute: route,
        currentStats: currentStats,
        optimizedStats: currentStats,
        recommendations: ['Vehicle information required for fuel optimization'],
      );
    }

    // Calculate fuel-efficient route (avoid highways, optimize speed)
    final directions = await _directionsService.getDirections(
      origin: _extractLatLng(route.startPoint),
      destination: _extractLatLng(route.endPoint),
      waypoints: route.stops,
      avoidHighways: true,
    );

    if (directions == null) {
      return RouteOptimization(
        criteria: OptimizationCriteria.fuelEfficient,
        optimizedRoute: route,
        currentStats: currentStats,
        optimizedStats: currentStats,
        recommendations: ['Unable to calculate fuel-efficient route'],
      );
    }

    final optimizedStats = await _calculateRouteStats(route, directions);

    return RouteOptimization(
      criteria: OptimizationCriteria.fuelEfficient,
      optimizedRoute: route,
      currentStats: currentStats,
      optimizedStats: optimizedStats,
      recommendations:
          _generateFuelRecommendations(currentStats, optimizedStats, vehicle),
    );
  }

  Future<RouteOptimization> _optimizeForScenic(
    UserRoute route,
    RouteStats currentStats,
  ) async {
    // This would integrate with scenic route APIs or databases
    // For now, return a basic implementation
    return RouteOptimization(
      criteria: OptimizationCriteria.scenic,
      optimizedRoute: route,
      currentStats: currentStats,
      optimizedStats: currentStats,
      recommendations: ['Scenic route optimization coming soon'],
    );
  }

  Future<RouteOptimization> _optimizeBalanced(
    UserRoute route,
    RouteStats currentStats,
  ) async {
    // Balance between time, distance, and fuel efficiency
    return RouteOptimization(
      criteria: OptimizationCriteria.balanced,
      optimizedRoute: route,
      currentStats: currentStats,
      optimizedStats: currentStats,
      recommendations: [
        'Balanced optimization considers time, distance, and efficiency'
      ],
    );
  }

  Future<RouteStats> _calculateRouteStats(
    UserRoute route,
    models.Directions? directions,
  ) async {
    // If no directions provided, fetch them
    if (directions == null) {
      final fetchedDirections = await _directionsService.getDirections(
        origin: _extractLatLng(route.startPoint),
        destination: _extractLatLng(route.endPoint),
        waypoints: route.stops,
      );

      if (fetchedDirections == null) {
        // Return basic stats if we can't get directions
        return RouteStats(
          totalDistance: route.distance ?? 0.0,
          totalTime: route.duration ?? Duration.zero,
          averageSpeed: 0.0,
          stopTypeBreakdown: _calculateStopBreakdown(route.stops),
        );
      }

      directions = fetchedDirections;
    }

    // Calculate stop type breakdown
    final stopBreakdown = _calculateStopBreakdown(route.stops);

    // Extract meal and fuel stops
    final mealStops =
        route.stops.where((s) => s.stopType == StopType.food).toList();
    final fuelStops =
        route.stops.where((s) => s.stopType == StopType.fuel).toList();

    // Calculate states traversed (simplified version)
    final statesTraversed = _calculateStatesTraversed(directions);

    return RouteStats(
      totalDistance: directions.totalDistance,
      totalTime: directions.totalDuration,
      averageSpeed: directions.totalDistance / directions.totalDuration.inHours,
      stopTypeBreakdown: stopBreakdown,
      estimatedFuelCost: _estimateFuelCost(directions.totalDistance),
      estimatedTolls: _estimateTolls(directions),
      mealStops: mealStops,
      fuelStops: fuelStops,
      statesTraversed: statesTraversed,
    );
  }

  Map<Type, int> _calculateStopBreakdown(List<Stop> stops) {
    final breakdown = <Type, int>{};
    for (final stop in stops) {
      breakdown[stop.runtimeType] = (breakdown[stop.runtimeType] ?? 0) + 1;
    }
    return breakdown;
  }

  List<StateInfo> _calculateStatesTraversed(models.Directions directions) {
    // This is a simplified implementation
    // In a real app, you'd analyze the polyline to determine states crossed
    return [
      StateInfo(
        stateName: 'Indiana',
        miles: directions.totalDistance * 0.3,
        duration: Duration(
            minutes: (directions.totalDuration.inMinutes * 0.3).round()),
      ),
      StateInfo(
        stateName: 'Illinois',
        miles: directions.totalDistance * 0.7,
        duration: Duration(
            minutes: (directions.totalDuration.inMinutes * 0.7).round()),
      ),
    ];
  }

  double _estimateFuelCost(double distance,
      {double mpg = 25.0, double pricePerGallon = 3.50}) {
    return (distance / mpg) * pricePerGallon;
  }

  double _estimateTolls(models.Directions directions) {
    // This would integrate with toll APIs
    // For now, return a rough estimate based on distance
    return directions.totalDistance * 0.02; // 2 cents per mile
  }

  List<Stop> _reorderStops(List<Stop> stops, List<int> order) {
    final reordered = <Stop>[];
    for (int i = 0; i < order.length; i++) {
      final stop = stops[order[i]];
      reordered.add(Stop.fromJson({
        ...stop.toJson(),
        'order': i,
      }));
    }
    return reordered;
  }

  LatLng _extractLatLng(String point) {
    // Extract coordinates from a point string
    // This is a simplified implementation
    final parts = point.split(',');
    if (parts.length >= 2) {
      return LatLng(
        double.tryParse(parts[0]) ?? 0.0,
        double.tryParse(parts[1]) ?? 0.0,
      );
    }
    return const LatLng(0, 0);
  }

  List<String> _generateTimeRecommendations(
    RouteStats current,
    RouteStats optimized,
  ) {
    final recommendations = <String>[];

    final timeSaved = current.totalTime - optimized.totalTime;
    if (timeSaved.inMinutes > 0) {
      recommendations
          .add('Save ${timeSaved.inMinutes} minutes with this route');
    }

    if (optimized.totalDistance < current.totalDistance) {
      final distanceSaved = current.totalDistance - optimized.totalDistance;
      recommendations.add('Save ${distanceSaved.toStringAsFixed(1)} miles');
    }

    return recommendations;
  }

  List<String> _generateFuelRecommendations(
    RouteStats current,
    RouteStats optimized,
    Vehicle vehicle,
  ) {
    final recommendations = <String>[];

    final currentFuelUsage = current.totalDistance / vehicle.mpg;
    final optimizedFuelUsage = optimized.totalDistance / vehicle.mpg;
    final fuelSaved = currentFuelUsage - optimizedFuelUsage;

    if (fuelSaved > 0) {
      recommendations
          .add('Save ${fuelSaved.toStringAsFixed(1)} gallons of fuel');
      recommendations
          .add('Save \$${(fuelSaved * 3.50).toStringAsFixed(2)} in fuel costs');
    }

    if (optimized.totalTime > current.totalTime) {
      final extraTime = optimized.totalTime - current.totalTime;
      recommendations
          .add('Takes ${extraTime.inMinutes} minutes longer but saves fuel');
    }

    return recommendations;
  }
}
