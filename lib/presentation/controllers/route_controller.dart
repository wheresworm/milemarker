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
      final waypoints = _stops.map((s) => s.location).toList();
      final directions = await _directionsService.getDirections(
        waypoints: waypoints,
      );

      // Create temporary route for display
      _currentRoute = UserRoute(
        name: 'Current Route',
        stops: _stops,
        totalDistance: directions.totalDistance,
        totalDuration: directions.totalDuration,
        polylinePoints: directions.polylinePoints,
      );

      _updatePolylines();
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
