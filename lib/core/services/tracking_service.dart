// lib/core/services/tracking_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../models/user_route.dart';
import 'location_service.dart';
import 'route_service.dart';

class TrackingService extends ChangeNotifier {
  final LocationService _locationService;
  final RouteService _routeService;

  // In-memory storage instead of Firebase
  final Map<String, dynamic> _tripStore = {};
  final Map<String, dynamic> _routeStore = {};
  final Map<String, dynamic> _statsStore = {};

  Trip? _currentTrip;
  LatLng? _currentLocation;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  Duration _totalDuration = Duration.zero;
  List<LatLng> _trackPoints = [];
  bool _isTracking = false;
  StreamSubscription<dynamic>? _locationSubscription;

  DateTime? _trackingStartTime;
  DateTime? _lastLocationUpdate;
  String? _currentTripId;

  // Getters
  Trip? get currentTrip => _currentTrip;
  String? get currentTripId => _currentTripId;
  LatLng? get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  Duration get totalDuration => _totalDuration;
  List<LatLng> get trackPoints => _trackPoints;
  bool get isTracking => _isTracking;

  TrackingService({
    required LocationService locationService,
    required RouteService routeService,
  })  : _locationService = locationService,
        _routeService = routeService;

  Future<void> saveUserRoute(UserRoute route) async {
    try {
      // Store in memory instead of Firebase
      _routeStore[route.id] = route.toJson();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveTrip(Trip trip) async {
    try {
      // Store in memory instead of Firebase
      _tripStore[trip.id] = trip.toJson();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startTracking(UserRoute route) async {
    if (_isTracking) {
      return;
    }

    // Start a new trip for this route
    _currentTrip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Trip for ${route.title}",
      routeId: route.id,
      status: TripStatus.active,
      lastUpdated: DateTime.now(),
      route: route,
      startTime: DateTime.now(),
    );

    _currentTripId = _currentTrip!.id;

    // Save the new trip
    await saveTrip(_currentTrip!);

    // Reset tracking data
    _trackPoints = [];
    _totalDistance = 0.0;
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _trackingStartTime = DateTime.now();
    _lastLocationUpdate = null;

    // Start location tracking - use locationStream which should return Position
    _locationSubscription =
        _locationService.locationStream.listen(_handleLocationUpdate);
    _isTracking = true;
    notifyListeners();
  }

  Future<void> pauseTracking() async {
    if (!_isTracking || _locationSubscription == null) {
      return;
    }

    _locationSubscription?.pause();

    // Update trip status
    if (_currentTrip != null) {
      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.paused,
        lastUpdated: DateTime.now(),
      );
      await saveTrip(_currentTrip!);
    }

    _isTracking = false;
    notifyListeners();
  }

  Future<void> resumeTracking() async {
    if (_isTracking || _locationSubscription == null) {
      return;
    }

    _locationSubscription?.resume();

    // Update trip status
    if (_currentTrip != null) {
      _currentTrip = _currentTrip!.copyWith(
        status: TripStatus.active,
        lastUpdated: DateTime.now(),
      );
      await saveTrip(_currentTrip!);
    }

    _isTracking = true;
    notifyListeners();
  }

  Future<Trip> stopTracking() async {
    if (!_isTracking && _locationSubscription == null) {
      throw Exception('Tracking is not active');
    }

    // Clean up subscription
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
    }
    _isTracking = false;

    // Update trip with final statistics
    if (_currentTrip != null) {
      // Calculate final duration
      final endTime = DateTime.now();
      _totalDuration = endTime.difference(_trackingStartTime!);

      // Create updated trip
      final completedTrip = _currentTrip!.copyWith(
        status: TripStatus.completed,
        endTime: endTime,
        actualDuration: _totalDuration,
        lastUpdated: endTime,
        progress: 100.0,
        route: _currentTrip!.route?.copyWith(
          distance: _totalDistance,
          duration: _totalDuration,
        ),
      );

      // Save the completed trip
      await saveTrip(completedTrip);

      // Save route statistics
      await _saveRouteStats(
        tripId: completedTrip.id,
        totalDistance: _totalDistance,
        totalDuration: _totalDuration,
      );

      // Reset current trip
      _currentTrip = null;
      _currentTripId = null;

      notifyListeners();

      // Return the completed trip
      return completedTrip;
    } else {
      throw Exception('No active trip found');
    }
  }

  Future<void> _saveRouteStats({
    required String tripId,
    required double totalDistance,
    required Duration totalDuration,
  }) async {
    try {
      _statsStore[tripId] = {
        'tripId': tripId,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration.inSeconds,
        'maxSpeed': _maxSpeed,
        'averageSpeed': _totalDistance > 0 && _totalDuration.inSeconds > 0
            ? _totalDistance / (_totalDuration.inSeconds / 3600) // km/h
            : 0,
        'trackPoints': _trackPoints
            .map((point) => {
                  'lat': point.latitude,
                  'lng': point.longitude,
                })
            .toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Use a logger instead of print in production
      rethrow;
    }
  }

  // THIS IS THE MAIN CHANGE: Changed parameter type from LatLng to Position
  void _handleLocationUpdate(Position position) {
    // Convert Position to LatLng
    final location = LatLng(position.latitude, position.longitude);

    // Update current location
    final previousLocation = _currentLocation;
    _currentLocation = location;

    // Calculate speed and distance
    if (previousLocation != null && _lastLocationUpdate != null) {
      // Calculate distance between points
      final distance = _calculateDistance(previousLocation, location);
      _totalDistance += distance;

      // Calculate speed
      final now = DateTime.now();
      final timeDiff = now.difference(_lastLocationUpdate!).inMilliseconds /
          1000; // in seconds
      if (timeDiff > 0) {
        _currentSpeed = distance / timeDiff * 3600; // km/h

        // Update max speed
        if (_currentSpeed > _maxSpeed) {
          _maxSpeed = _currentSpeed;
        }
      }

      _lastLocationUpdate = now;
    } else {
      _lastLocationUpdate = DateTime.now();
    }

    // Add point to track
    _trackPoints.add(location);

    // Update duration
    if (_trackingStartTime != null) {
      _totalDuration = DateTime.now().difference(_trackingStartTime!);
    }

    // Update trip if exists
    if (_currentTrip != null) {
      // Calculate progress based on distance or some other metric
      final progress = _currentTrip!.route?.distance != null &&
              _currentTrip!.route!.distance! > 0
          ? (_totalDistance / _currentTrip!.route!.distance!) * 100
          : _currentTrip!.progress;

      // Update current trip with latest data
      _currentTrip = _currentTrip!.copyWith(
        lastUpdated: DateTime.now(),
        progress: progress.clamp(0.0, 100.0),
      );
    }

    notifyListeners();
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // in kilometers

    final lat1 = start.latitude * (pi / 180);
    final lon1 = start.longitude * (pi / 180);
    final lat2 = end.latitude * (pi / 180);
    final lon2 = end.longitude * (pi / 180);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // in kilometers
  }

  // Additional method for simulation purposes (development only)
  void simulateLocationUpdate(LatLng location) {
    if (_isTracking) {
      // For simulation, we need to create a Position-like object
      // This is just for development/testing purposes
      final position = Position(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _handleLocationUpdate(position);
    }
  }

  Future<List<Trip>> getTripHistory() async {
    try {
      // Get completed trips from in-memory storage
      final trips = _tripStore.values
          .where((tripData) =>
              tripData['status'] ==
              TripStatus.completed.toString().split('.').last)
          .map((tripData) => Trip.fromJson(tripData as Map<String, dynamic>))
          .toList();

      // Sort by last updated
      trips.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return trips;
    } catch (e) {
      rethrow;
    }
  }

  Future<Trip?> getTripById(String tripId) async {
    try {
      if (_tripStore.containsKey(tripId)) {
        return Trip.fromJson(_tripStore[tripId] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      _tripStore.remove(tripId);
      _statsStore.remove(tripId);
    } catch (e) {
      rethrow;
    }
  }
}
