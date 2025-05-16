import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/stop.dart';
import '../../core/models/user_route.dart';
import '../../core/models/user_preferences.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/route_service.dart';

class RouteController extends ChangeNotifier {
  final RouteService _routeService;
  final DirectionsService _directionsService;

  List<Stop> _stops = [];
  UserRoute? _currentRoute;
  Set<Polyline> _polylines = {};
  bool _isLoading = false;
  String? _error;

  List<Stop> get stops => _stops;
  UserRoute? get currentRoute => _currentRoute;
  Set<Polyline> get polylines => _polylines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RouteController({
    required RouteService routeService,
    required DirectionsService directionsService,
  })  : _routeService = routeService,
        _directionsService = directionsService {
    // Listen to route service changes
    _routeService.addListener(_onRouteServiceChanged);
  }

  void _onRouteServiceChanged() {
    _currentRoute = _routeService.currentRoute;
    if (_currentRoute != null) {
      _stops = List.from(_currentRoute!.stops);
      _updatePolylines();
    }
    notifyListeners();
  }

  Future<void> createRoute({
    required String name,
    DateTime? departureTime,
  }) async {
    if (_stops.isEmpty) {
      _error = 'At least one stop is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final route = await _routeService.createRoute(
        name: name,
        stops: _stops,
        departureTime: departureTime,
      );

      _currentRoute = route;
      _updatePolylines();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method to your RouteController class in route_controller.dart
  Future<void> buildRoute({
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destinationName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Clear existing stops and add new origin and destination
      _stops = [
        Stop(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: originName,
          location: origin,
          order: 0,
        ),
        Stop(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: destinationName,
          location: destination,
          order: 1,
        ),
      ];

      // Get directions between the points
      final directions = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        waypoints: null,
      );

      if (directions != null) {
        _currentRoute = UserRoute(
          title: '$originName to $destinationName',
          startPoint: '${origin.latitude},${origin.longitude}',
          endPoint: '${destination.latitude},${destination.longitude}',
          stops: _stops,
          distance: directions.totalDistance,
          duration: directions.totalDuration,
          polylinePoints: directions.polylinePoints,
        );

        _updatePolylines();
      } else {
        _error = "Could not get directions";
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStop(Stop stop) async {
    _stops.add(stop);
    notifyListeners();

    if (_stops.length >= 2) {
      await _updateRoute();
    }
  }

  Future<void> removeStop(int index) async {
    if (index < 0 || index >= _stops.length) return;

    _stops.removeAt(index);
    notifyListeners();

    if (_stops.length >= 2) {
      await _updateRoute();
    }
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final stop = _stops.removeAt(oldIndex);
    _stops.insert(newIndex, stop);
    notifyListeners();

    await _updateRoute();
  }

  Future<void> _updateRoute() async {
    if (_stops.length < 2) {
      _polylines.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, extract start and end points - DEFINE THESE FIRST!
      final start = _stops.first.location;
      final end = _stops.last.location;

      // Then use them in the directions call
      final directions = await _directionsService.getDirections(
        origin: start,
        destination: end,
        waypoints:
            _stops.length > 2 ? _stops.sublist(1, _stops.length - 1) : null,
      );

      if (directions != null) {
        _currentRoute = UserRoute(
          title: 'Current Route',
          startPoint: '${start.latitude},${start.longitude}',
          endPoint: '${end.latitude},${end.longitude}',
          stops: _stops,
          distance: directions.totalDistance,
          duration: directions.totalDuration,
          polylinePoints: directions.polylinePoints,
        );

        _updatePolylines();
      } else {
        _error = "Could not get directions";
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updatePolylines() {
    if (_currentRoute?.polylinePoints == null) {
      _polylines.clear();
      return;
    }

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _currentRoute!.polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  Future<void> optimizeRoute() async {
    if (_stops.length < 3) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final optimizedStops = await _routeService.optimizeRoute(_stops);
      _stops = optimizedStops;
      await _updateRoute();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSmartStops(UserPreferences preferences) async {
    if (_currentRoute == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stopsWithSmart = await _routeService.addSmartStops(
        _currentRoute!,
        preferences,
      );

      _stops = stopsWithSmart;
      await _updateRoute();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _stops.clear();
    _currentRoute = null;
    _polylines.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _routeService.removeListener(_onRouteServiceChanged);
    super.dispose();
  }
}
