import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/fuel_stop.dart';
import '../models/place_stop.dart';
import '../models/directions.dart';
import 'directions_service.dart';
import 'food_stop_service.dart';
import 'fuel_planning_service.dart';

class RouteOptimizationService {
  final DirectionsService directionsService;
  final FoodStopService foodStopService;
  final FuelPlanningService fuelPlanningService;

  RouteOptimizationService({
    required this.directionsService,
    required this.foodStopService,
    required this.fuelPlanningService,
  });

  // Optimize route with all stops
  Future<route_model.Route> optimizeRoute({
    required route_model.Route route,
    required OptimizationPreferences preferences,
  }) async {
    // Separate fixed and flexible stops
    final fixedStops = <Stop>[];
    final flexibleStops = <Stop>[];

    for (final stop in route.stops) {
      if (stop is FoodStop || stop is FuelStop) {
        flexibleStops.add(stop);
      } else {
        fixedStops.add(stop);
      }
    }

    // Optimize order of flexible stops
    final optimizedStops = await _optimizeStopOrder(
      origin: route.origin,
      destination: route.destination,
      fixedStops: fixedStops,
      flexibleStops: flexibleStops,
      preferences: preferences,
    );

    // Get directions for optimized route
    final directions = await directionsService.getDirections(
      origin: route.origin,
      destination: route.destination,
      waypoints: optimizedStops
          .where((s) =>
              s.location != route.origin && s.location != route.destination)
          .map((s) => s.location)
          .toList(),
      avoidTolls: preferences.avoidTolls,
      avoidHighways: preferences.avoidHighways,
      departureTime: route.departureTime,
    );

    // Calculate route stats
    final stats = _calculateRouteStats(
      stops: optimizedStops,
      directions: directions,
      preferences: preferences,
    );

    return route.copyWith(
      stops: optimizedStops,
      directions: directions,
      stats: stats,
    );
  }

  // Find best order for stops
  Future<List<Stop>> _optimizeStopOrder({
    required LatLng origin,
    required LatLng destination,
    required List<Stop> fixedStops,
    required List<Stop> flexibleStops,
    required OptimizationPreferences preferences,
  }) async {
    if (flexibleStops.isEmpty) return fixedStops;

    // Get optimal waypoint order from Google
    final allWaypoints = [
      ...fixedStops.map((s) => s.location),
      ...flexibleStops.map((s) => s.location),
    ];

    final optimizedIndices = await directionsService.optimizeWaypoints(
      origin: origin,
      destination: destination,
      waypoints: allWaypoints,
    );

    // Reconstruct stop list with optimized order
    final allStops = [...fixedStops, ...flexibleStops];
    final optimizedStops = <Stop>[
      // Origin stop
      allStops.firstWhere((s) => s.location == origin),
    ];

    // Add waypoints in optimized order
    for (final index in optimizedIndices) {
      final stop = allStops[index + 1]; // +1 because origin is at index 0
      optimizedStops.add(stop.copyWith(order: optimizedStops.length));
    }

    // Add destination
    optimizedStops.add(
      allStops
          .firstWhere((s) => s.location == destination)
          .copyWith(order: optimizedStops.length),
    );

    return optimizedStops;
  }

  // Calculate comprehensive route statistics
  route_model.RouteStats _calculateRouteStats({
    required List<Stop> stops,
    required Directions directions,
    required OptimizationPreferences preferences,
  }) {
    // Count stops by type
    final mealStops = <MealType, int>{};
    int fuelStops = 0;

    for (final stop in stops) {
      if (stop is FoodStop) {
        mealStops[stop.mealType] = (mealStops[stop.mealType] ?? 0) + 1;
      } else if (stop is FuelStop) {
        fuelStops++;
      }
    }

    // Calculate costs
    final fuelCost = _estimateFuelCost(
      distance: directions.totalDistance,
      mpg: preferences.vehicle?.mpg ?? 25.0,
      pricePerGallon: 3.50, // Average price
    );

    final tolls = _estimateTolls(directions);

    // State information
    final states = _getStatesTraversed(directions);

    return route_model.RouteStats(
      totalDuration: directions.totalDuration,
      totalDistance: directions.totalDistance,
      estimatedFuelCost: fuelCost,
      estimatedTolls: tolls,
      numberOfStops: stops.length,
      mealStops: mealStops,
      fuelStops: fuelStops,
      statesTraversed: states,
    );
  }

  double _estimateFuelCost({
    required double distance,
    required double mpg,
    required double pricePerGallon,
  }) {
    final gallonsNeeded = distance / mpg;
    return gallonsNeeded * pricePerGallon;
  }

  double _estimateTolls(Directions directions) {
    // Simplified toll estimation
    // In production, use toll API
    return directions.totalDistance * 0.02; // $0.02 per mile average
  }

  List<route_model.StateInfo> _getStatesTraversed(Directions directions) {
    // In production, use reverse geocoding to determine states
    // For now, return mock data
    return [
      route_model.StateInfo(
        name: 'California',
        abbreviation: 'CA',
        milesInState: 350,
        timeInState: const Duration(hours: 5),
        speedLimit: 70,
      ),
      route_model.StateInfo(
        name: 'Nevada',
        abbreviation: 'NV',
        milesInState: 200,
        timeInState: const Duration(hours: 3),
        speedLimit: 75,
      ),
    ];
  }

  // Quick optimization for common scenarios
  Future<route_model.Route> quickOptimize({
    required route_model.Route route,
    required OptimizationType type,
  }) async {
    switch (type) {
      case OptimizationType.fastest:
        return optimizeRoute(
          route: route,
          preferences: OptimizationPreferences(
            optimizationGoal: route_model.RouteOptimization.fastest,
            avoidHighways: false,
            avoidTolls: false,
          ),
        );

      case OptimizationType.fuelEfficient:
        return optimizeRoute(
          route: route,
          preferences: OptimizationPreferences(
            optimizationGoal: route_model.RouteOptimization.fuelEfficient,
            avoidHighways: true,
            preferredSpeed: 55,
          ),
        );

      case OptimizationType.scenic:
        return optimizeRoute(
          route: route,
          preferences: OptimizationPreferences(
            optimizationGoal: route_model.RouteOptimization.scenic,
            avoidHighways: true,
            preferBackroads: true,
          ),
        );
    }
  }
}

class OptimizationPreferences {
  final route_model.RouteOptimization optimizationGoal;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool preferBackroads;
  final int? preferredSpeed;
  final Vehicle? vehicle;
  final bool minimizeStops;

  OptimizationPreferences({
    required this.optimizationGoal,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.preferBackroads = false,
    this.preferredSpeed,
    this.vehicle,
    this.minimizeStops = false,
  });
}

enum OptimizationType { fastest, fuelEfficient, scenic }
