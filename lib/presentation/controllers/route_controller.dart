import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/trip.dart';
import '../../core/models/route.dart' as route_model;
import '../../core/services/route_service.dart';
import '../../core/services/database_service.dart';

class RouteController extends ChangeNotifier {
  final RouteService _routeService;
  final DatabaseService _databaseService;

  Trip? _currentTrip;
  route_model.Route? _currentRoute;
  bool _isLoading = false;

  RouteController(this._routeService, this._databaseService);

  Trip? get currentTrip => _currentTrip;
  route_model.Route? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;

  Future<void> buildRoute({
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destinationName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final route = await _routeService.createRoute(
        origin: origin,
        destination: destination,
        startTime: DateTime.now(),
        averageSpeed: 65.0, // default average speed
        maxSpeed: 75.0, // default max speed
        distance: 0.0, // will be calculated by service
        duration: const Duration(seconds: 0), // will be calculated by service
      );

      _currentRoute = route;

      // Create a new trip
      _currentTrip = Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        route: route,
      );

      // Save to database
      await _databaseService.saveRoute(route);
    } catch (e) {
      print('Error building route: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
