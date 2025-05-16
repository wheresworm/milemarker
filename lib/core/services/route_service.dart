// Updated RouteService.dart
import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../models/trip.dart';
import '../models/user_route.dart';
import '../models/user_preferences.dart';
import '../services/database_service.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import '../services/food_stop_service.dart';
import '../services/fuel_planning_service.dart';
import '../models/food_stop.dart';
import '../models/vehicle.dart';

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
      // Assuming you've implemented the getRoutes method in DatabaseService
      _routes = await _databaseService
          .getUserRoutes(); // Changed from getRoutes to getUserRoutes
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
      if (stops.isEmpty) {
        throw Exception('Route must have at least one stop');
      }

      // Extract origin and destination
      final origin = stops.first.location;
      final destination = stops.last.location;

      // Use intermediate stops as waypoints if any
      final waypointStops =
          stops.length > 2 ? stops.sublist(1, stops.length - 1) : null;

      // Calculate route details
      final directions = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        waypoints: waypointStops,
        departureTime: departureTime,
      );

      if (directions == null) {
        throw Exception('Failed to calculate route directions');
      }

      final route = UserRoute(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Generate a temporary ID
        title: name,
        startPoint: '${origin.latitude},${origin.longitude}',
        endPoint: '${destination.latitude},${destination.longitude}',
        stops: stops,
        distance: directions.totalDistance,
        duration: directions.totalDuration,
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
        useCount: 0,
        notes: '',
      );

      // Save to database
      await _databaseService
          .saveUserRoute(route); // Changed from saveRoute to saveUserRoute
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
      await _databaseService.updateUserRoute(
          route); // Changed from updateRoute to updateUserRoute
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
      await _databaseService.deleteUserRoute(
          routeId); // Changed from deleteRoute to deleteUserRoute
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
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
        routeId: route.id,
        title: 'Trip on ${route.title}',
        startTime: DateTime.now(),
        lastUpdated: DateTime.now(),
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
        title: _activeTrip!.title,
        startTime: _activeTrip!.startTime,
        endTime: DateTime.now(),
        lastUpdated: DateTime.now(),
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
    final List<FoodPreference> foodPreferences = [];

    // Convert MealPreferences to List<FoodPreference>
    if (preferences.mealPreferences != null) {
      if (preferences.mealPreferences!.avoidFastFood == true) {
        foodPreferences.add(
            FoodPreference.fastService); // Add the opposite preference to avoid
      }
      if (preferences.mealPreferences!.dietaryRestrictions
              ?.contains('vegetarian') ==
          true) {
        foodPreferences.add(FoodPreference.vegetarian);
      }
      if (preferences.mealPreferences!.dietaryRestrictions?.contains('vegan') ==
          true) {
        foodPreferences.add(FoodPreference.vegan);
      }
      if (preferences.mealPreferences!.dietaryRestrictions
              ?.contains('gluten-free') ==
          true) {
        foodPreferences.add(FoodPreference.glutenFree);
      }
      // Add more mappings based on your MealPreferences properties
      // For example, if you have a 'halalPreferred' property:
      // if (preferences.mealPreferences!.halalPreferred == true) {
      //   foodPreferences.add(FoodPreference.halal);
      // }
    }

    // Add meal stops
    if (foodPreferences.isNotEmpty && route.departureTime != null) {
      final mealSuggestions = await _foodStopService.suggestMealStops(
        route: route,
        preferences: foodPreferences,
        departureTime: route.departureTime!,
      );

      // Convert FoodSuggestion to FoodStop if needed
      stops.addAll(
          mealSuggestions.map((suggestion) => suggestion as Stop).toList());
    }

    // Add fuel stops
    if (preferences.vehicleProfile != null) {
      // Create a Vehicle from the VehicleProfile
      final vehicle = Vehicle(
        id: preferences.vehicleProfile!.id,
        name: preferences.vehicleProfile!.name,
        mpg: preferences.vehicleProfile!.mpg,
        tankSize: preferences.vehicleProfile!.tankSize,
        fuelType:
            preferences.vehicleProfile!.fuelType.toString().split('.').last,
      );

      final fuelStops = await _fuelPlanningService.suggestFuelStops(
        route: route,
        vehicle: vehicle,
        currentFuelLevel:
            0.0, // Default to empty tank since this isn't in VehicleProfile
      );
      stops.addAll(fuelStops);
    }
    return optimizeRoute(stops);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
