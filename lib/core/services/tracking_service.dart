import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../utils/location_point.dart';
import 'database_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  Trip? _currentTrip;
  Trip? get currentTrip => _currentTrip;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  StreamSubscription<Position>? _locationSubscription;
  final List<LocationPoint> _currentRoute = [];
  DateTime? _trackingStartTime;
  double _totalDistance = 0.0;
  double _maxSpeed = 0.0;

  Future<void> startTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    _trackingStartTime = DateTime.now();
    _currentRoute.clear();
    _totalDistance = 0.0;
    _maxSpeed = 0.0;

    _locationService.startLocationTracking();

    _locationSubscription = _locationService.locationStream.listen((position) {
      _handleLocationUpdate(position);
    });

    await _notificationService.showTrackingNotification(
      title: 'Tracking Active',
      body: 'MileMarker is tracking your trip',
    );

    _currentTrip = Trip(
      startTime: _trackingStartTime!,
      distance: 0,
      duration: Duration.zero,
      route: [],
      averageSpeed: 0,
      maxSpeed: 0,
    );
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    _locationSubscription?.cancel();
    _locationService.stopLocationTracking();
    await _notificationService.cancelTrackingNotification();

    if (_currentRoute.isNotEmpty) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_trackingStartTime!);
      final averageSpeed = _totalDistance / duration.inSeconds;

      _currentTrip = Trip(
        startTime: _trackingStartTime!,
        endTime: endTime,
        distance: _totalDistance,
        duration: duration,
        route: List.from(_currentRoute),
        averageSpeed: averageSpeed,
        maxSpeed: _maxSpeed,
      );

      await _databaseService.insertTrip(_currentTrip!);
    }

    _currentRoute.clear();
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
  }

  void _handleLocationUpdate(Position position) {
    final newPoint = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
    );

    if (_currentRoute.isNotEmpty) {
      final lastPoint = _currentRoute.last;
      final distance = newPoint.distanceTo(lastPoint);
      _totalDistance += distance;
    }

    _currentRoute.add(newPoint);

    if (position.speed > _maxSpeed) {
      _maxSpeed = position.speed;
    }

    // Update current trip
    if (_currentTrip != null) {
      final duration = DateTime.now().difference(_trackingStartTime!);
      final averageSpeed = _totalDistance / duration.inSeconds;

      _currentTrip = _currentTrip!.copyWith(
        distance: _totalDistance,
        duration: duration,
        route: List.from(_currentRoute),
        averageSpeed: averageSpeed,
        maxSpeed: _maxSpeed,
      );
    }
  }
}
