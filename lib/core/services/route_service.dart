import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/favorite_route.dart';
import '../models/stop.dart';
import '../models/trip.dart';
import '../models/user_route.dart';
import '../models/user_preferences.dart';
import '../services/database_service.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import '../services/food_stop_service.dart';
import '../services/fuel_planning_service.dart';

class RouteService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final PlacesService _placesService;
  final DirectionsService _directionsService;
  final FoodStopService _foodStopService;
  final FuelPlanningService _fuelPlanningService;

  List<UserRoute> _routes = [];
  UserRoute? _currentRoute;
  Trip? _activeTrip;
  bool _isLoading = false;
  String? _error;

  List<UserRoute> get routes => _routes;
  UserRoute? get currentRoute => _currentRoute;
  Trip? get activeTrip => _activeTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RouteService({
    required DatabaseService databaseService,
    required PlacesService placesService,
    required DirectionsService directionsService,
    required FoodStopService foodStopService,
    required FuelPlanningService fuelPlanningService,
  })  : _databaseService = databaseService,
        _placesService = placesService,
        _directionsService = directionsService,
        _foodStopService = foodStopService,
        _fuelPlanningService = fuelPlanningService {
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _databaseService.getRoutes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load routes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserRoute> createRoute({
    required String name,
    required List<Stop> stops,
    DateTime? departureTime,
    UserPreferences? preferences,
  }) async {
    try {
      // Calculate route details
      final locationPoints = stops.map((s) => s.location).toList();
      final directions = await _directionsService.getDirections(
        waypoints: locationPoints,
        departureTime: departureTime,
      );

      final route = UserRoute(
        name: name,
        stops: stops,
        totalDistance: directions.totalDistance,
        totalDuration: directions.totalDuration,
        polylinePoints: directions.polylinePoints,
        departureTime: departureTime,
      );

      // Save to database
      await _databaseService.saveRoute(route);
      await loadRoutes();

      _currentRoute = route;
      notifyListeners();

      return route;
    } catch (e) {
      _error = 'Failed to create route: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoute(UserRoute route) async {
    try {
      await _databaseService.updateRoute(route);
      await loadRoutes();

      if (_currentRoute?.id == route.id) {
        _currentRoute = route;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update route: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _databaseService.deleteRoute(routeId);
      await loadRoutes();

      if (_currentRoute?.id == routeId) {
        _currentRoute = null;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete route: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setCurrentRoute(UserRoute? route) async {
    _currentRoute = route;
    notifyListeners();
  }

  Future<Trip> startTrip(UserRoute route) async {
    try {
      final trip = Trip(
        routeId: route.id,
        startTime: DateTime.now(),
        status: TripStatus.active,
      );

      await _databaseService.saveTrip(trip);
      _activeTrip = trip;
      _currentRoute = route;
      notifyListeners();

      return trip;
    } catch (e) {
      _error = 'Failed to start trip: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> endTrip() async {
    if (_activeTrip == null) return;

    try {
      final updatedTrip = Trip(
        id: _activeTrip!.id,
        routeId: _activeTrip!.routeId,
        startTime: _activeTrip!.startTime,
        endTime: DateTime.now(),
        status: TripStatus.completed,
      );

      await _databaseService.updateTrip(updatedTrip);
      _activeTrip = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end trip: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Stop>> optimizeRoute(List<Stop> stops) async {
    // Simple optimization - keep first and last stops fixed
    if (stops.length <= 2) return stops;

    final origin = stops.first;
    final destination = stops.last;
    final waypoints = stops.sublist(1, stops.length - 1);

    // This is a placeholder for more sophisticated optimization
    // In a real implementation, you might want to use the Google Directions API
    // optimize waypoints feature or implement a traveling salesman algorithm

    final optimizedStops = [origin, ...waypoints, destination];
    return optimizedStops;
  }

  Future<List<Stop>> addSmartStops(
    UserRoute route,
    UserPreferences preferences,
  ) async {
    final stops = List<Stop>.from(route.stops);

    // Add meal stops
    if (preferences.mealPreferences != null) {
      final mealStops = await _foodStopService.suggestMealStops(
        route: route,
        preferences: preferences.mealPreferences!,
      );
      stops.addAll(mealStops);
    }

    // Add fuel stops
    if (preferences.vehicleProfile != null) {
      final fuelStops = await _fuelPlanningService.calculateFuelStops(
        route: route,
        vehicleProfile: preferences.vehicleProfile!,
      );
      stops.addAll(fuelStops);
    }

    // Re-optimize the route with the new stops
    return optimizeRoute(stops);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
