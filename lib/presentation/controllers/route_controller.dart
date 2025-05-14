import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/trip.dart';
import '../../core/models/route.dart' as route_model;
import '../../core/models/route_segment.dart';
import '../../core/models/place_stop.dart';
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
      // Create the route using the correct method from RouteService
      final segments = await _routeService.getDetailedRoute(
        origin: origin,
        destination: destination,
        departureTime: DateTime.now(),
      );

      // Create route model
      _currentRoute = route_model.Route(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '$originName to $destinationName',
        departureTime: DateTime.now(),
        segments: segments,
        stops: [], // Initially empty, user can add stops later
      );

      // Create a new trip
      _currentTrip = Trip(
        id: 0, // Will be assigned by the database
        route: _currentRoute!,
        startTime: DateTime.now(),
        averageSpeed: 0.0,
        maxSpeed: 0.0,
        distance: _currentRoute!.totalMiles,
        duration: Duration(minutes: _currentRoute!.estimatedDuration.inMinutes),
        locationPoints: [], // Will be populated during tracking
      );

      // Save to database
      await _databaseService.saveRoute(_currentRoute!);
    } catch (e) {
      print('Error building route: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addStop(PlaceStop stop) async {
    if (_currentRoute != null) {
      _currentRoute!.stops.add(stop);
      notifyListeners();
    }
  }

  Future<void> removeStop(PlaceStop stop) async {
    if (_currentRoute != null) {
      _currentRoute!.stops.remove(stop);
      notifyListeners();
    }
  }
}
