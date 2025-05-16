import 'package:flutter/material.dart';
import '../../core/models/trip.dart';
import '../../core/models/user_route.dart'; // Add this import
import '../../core/services/tracking_service.dart';

class TrackingController extends ChangeNotifier {
  final TrackingService _trackingService;
  Trip? _currentTrip;
  bool _isTracking = false;
  String? get currentTripId =>
      _trackingService.currentTripId; // Add this getter

  TrackingController({required TrackingService trackingService})
      : _trackingService = trackingService;

  Trip? get currentTrip => _currentTrip;
  bool get isTracking => _isTracking;

  // Update this method to handle the Trip to UserRoute conversion
  void startTracking(Trip trip) {
    if (trip.route == null) {
      throw Exception('Cannot start tracking without a route');
    }

    _currentTrip = trip;
    _isTracking = true;
    _trackingService.startTracking(trip.route!); // Pass the route from the trip
    notifyListeners();
  }

  // Alternative overload if you want to keep backward compatibility
  void startTrackingWithRoute(UserRoute route) {
    _isTracking = true;
    _trackingService.startTracking(route);
    notifyListeners();
  }

  Future<Trip> stopTracking() async {
    _isTracking = false;
    final completedTrip = await _trackingService.stopTracking();
    _currentTrip = completedTrip;
    notifyListeners();
    return completedTrip;
  }

  void pauseTracking() {
    _isTracking = false;
    _trackingService.pauseTracking();
    notifyListeners();
  }

  void resumeTracking() {
    _isTracking = true;
    _trackingService.resumeTracking();
    notifyListeners();
  }
}
