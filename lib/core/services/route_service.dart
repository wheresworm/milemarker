import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/fuel_stop.dart';
import '../models/place_stop.dart';
import '../models/place.dart';
import '../models/directions.dart';
import 'directions_service.dart';
import 'places_service.dart';
import 'food_stop_service.dart';
import 'fuel_planning_service.dart';
import 'route_optimization_service.dart';
import 'database_service.dart';

class RouteService {
  final DirectionsService directionsService;
  final PlacesService placesService;
  final FoodStopService foodStopService;
  final FuelPlanningService fuelPlanningService;
  final RouteOptimizationService optimizationService;
  final DatabaseService databaseService;

  RouteService({
    required this.directionsService,
    required this.placesService,
    required this.foodStopService,
    required this.fuelPlanningService,
    required this.optimizationService,
    required this.databaseService,
  });

  // Create a new route
  Future<route_model.Route> createRoute({
    required String name,
    required LatLng origin,
    required LatLng destination,
    required DateTime departureTime,
  }) async {
    final routeId = 'route_${DateTime.now().millisecondsSinceEpoch}';

    // Create initial stops
    final originStop = PlaceStop(
      id: 'origin_$routeId',
      location: origin,
      name: 'Start',
      order: 0,
      placeDetails: Place(
        id: 'origin',
        name: 'Starting Point',
        location: origin,
        address: '',
        type: PlaceType.other,
      ),
    );

    final destinationStop = PlaceStop(
      id: 'destination_$routeId',
      location: destination,
      name: 'End',
      order: 1,
      placeDetails: Place(
        id: 'destination',
        name: 'Destination',
        location: destination,
        address: '',
        type: PlaceType.other,
      ),
    );

    // Get initial directions
    final directions = await directionsService.getDirections(
      origin: origin,
      destination: destination,
      departureTime: departureTime,
    );

    // Create route
    final route = route_model.Route(
      id: routeId,
      name: name,
      stops: [originStop, destinationStop],
      departureTime: departureTime,
      directions: directions,
    );

    // Calculate stats
    final stats = await _calculateRouteStats(route);

    return route.copyWith(stats: stats);
  }

  // Add a stop to route
  Future<route_model.Route> addStop({
    required route_model.Route route,
    required Stop stop,
    int? position,
  }) async {
    final stops = List<Stop>.from(route.stops);

    // Add stop at specified position or end
    if (position != null && position < stops.length) {
      stops.insert(position, stop);
      // Update order indices
      for (int i = 0; i < stops.length; i++) {
        stops[i] = stops[i].copyWith(order: i);
      }
    } else {
      stop = stop.copyWith(order: stops.length);
      stops.add(stop);
    }

    // Rebuild route with new stop
    return await _rebuildRoute(route.copyWith(stops: stops));
  }

  // Remove a stop from route
  Future<route_model.Route> removeStop({
    required route_model.Route route,
    required String stopId,
  }) async {
    final stops = route.stops.where((s) => s.id != stopId).toList();

    // Update order indices
    for (int i = 0; i < stops.length; i++) {
      stops[i] = stops[i].copyWith(order: i);
    }

    return await _rebuildRoute(route.copyWith(stops: stops));
  }

  // Reorder stops
  Future<route_model.Route> reorderStops({
    required route_model.Route route,
    required List<Stop> newOrder,
  }) async {
    // Update order indices
    for (int i = 0; i < newOrder.length; i++) {
      newOrder[i] = newOrder[i].copyWith(order: i);
    }

    return await _rebuildRoute(route.copyWith(stops: newOrder));
  }

  // Add meal stops
  Future<route_model.Route> addMealStops({
    required route_model.Route route,
    required Vehicle vehicle,
  }) async {
    // Suggest meal times
    final mealStops = foodStopService.suggestMealTimes(route);

    // Add them to route
    var updatedRoute = route;
    for (final mealStop in mealStops) {
      updatedRoute = await addStop(
        route: updatedRoute,
        stop: mealStop,
      );
    }

    return updatedRoute;
  }

  // Add fuel stops
  Future<route_model.Route> addFuelStops({
    required route_model.Route route,
    required Vehicle vehicle,
    required double currentFuelLevel,
  }) async {
    final fuelStops = await fuelPlanningService.planFuelStops(
      route: route,
      vehicle: vehicle,
      currentFuelLevel: currentFuelLevel,
    );

    // Add them to route
    var updatedRoute = route;
    for (final fuelStop in fuelStops) {
      updatedRoute = await addStop(
        route: updatedRoute,
        stop: fuelStop,
      );
    }

    return updatedRoute;
  }

  // Find food options for a meal stop
  Future<route_model.Route> findFoodOptions({
    required route_model.Route route,
    required FoodStop mealStop,
  }) async {
    final suggestions = await foodStopService.findMealOptions(
      route: route,
      mealStop: mealStop,
      tripDate: route.departureTime,
    );

    // Update the meal stop with suggestions
    final updatedStop = mealStop.copyWith(suggestions: suggestions);
    final stops = route.stops.map((s) {
      return s.id == mealStop.id ? updatedStop : s;
    }).toList();

    return route.copyWith(stops: stops);
  }

  // Optimize route
  Future<route_model.Route> optimizeRoute({
    required route_model.Route route,
    required OptimizationPreferences preferences,
  }) async {
    return await optimizationService.optimizeRoute(
      route: route,
      preferences: preferences,
    );
  }

  // Save route
  Future<void> saveRoute(route_model.Route route) async {
    await databaseService.saveRoute(route);
  }

  // Load route
  Future<route_model.Route?> loadRoute(String routeId) async {
    return await databaseService.getRoute(routeId);
  }

  // Get saved routes
  Future<List<route_model.Route>> getSavedRoutes() async {
    return await databaseService.getAllRoutes();
  }

  // Private helper methods
  Future<route_model.Route> _rebuildRoute(route_model.Route route) async {
    // Skip if only origin and destination
    if (route.stops.length <= 2) {
      return route;
    }

    // Get new directions
    final directions = await directionsService.getDirections(
      origin: route.origin,
      destination: route.destination,
      waypoints: route.waypoints,
      departureTime: route.departureTime,
    );

    // Calculate stats
    final updatedRoute = route.copyWith(directions: directions);
    final stats = await _calculateRouteStats(updatedRoute);

    return updatedRoute.copyWith(stats: stats);
  }

  Future<route_model.RouteStats> _calculateRouteStats(
      route_model.Route route) async {
    // Count stop types
    final mealStops = <MealType, int>{};
    int fuelStops = 0;

    for (final stop in route.stops) {
      if (stop is FoodStop) {
        mealStops[stop.mealType] = (mealStops[stop.mealType] ?? 0) + 1;
      } else if (stop is FuelStop) {
        fuelStops++;
      }
    }

    // Estimate costs
    const averageMpg = 25.0;
    const averageGasPrice = 3.50;
    final fuelCost = (route.totalDistance / averageMpg) * averageGasPrice;
    final tolls = route.totalDistance * 0.02; // Rough estimate

    return route_model.RouteStats(
      totalDuration: route.directions?.totalDuration ?? Duration.zero,
      totalDistance: route.directions?.totalDistance ?? 0.0,
      estimatedFuelCost: fuelCost,
      estimatedTolls: tolls,
      numberOfStops: route.stops.length,
      mealStops: mealStops,
      fuelStops: fuelStops,
      statesTraversed: [], // Would calculate from directions
    );
  }
}
