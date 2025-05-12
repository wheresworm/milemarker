import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/directions_service.dart';
import '../../core/services/travel_time_optimizer.dart';
import '../../core/utils/logger.dart';
import '../models/route_data.dart';
import '../models/stop.dart';

class RouteProvider extends ChangeNotifier {
  final DirectionsService _directionsService;

  // Basic route information
  String? startAddress;
  String? destinationAddress;
  LatLng? startLocation;
  LatLng? destinationLocation;
  DateTime departureTime = DateTime.now();

  // Stops along the route
  List<Stop> stops = [];

  // Current route data
  RouteData? routeData;

  // Loading state
  bool isLoading = false;
  String? errorMessage;

  RouteProvider({DirectionsService? directionsService})
    : _directionsService = directionsService ?? DirectionsService();

  // Set the start location
  void setStartLocation(String address, LatLng location) {
    startAddress = address;
    startLocation = location;
    AppLogger.info('RouteProvider: Start location set to $address');
    notifyListeners();
  }

  // Set the destination location
  void setDestinationLocation(String address, LatLng location) {
    destinationAddress = address;
    destinationLocation = location;
    AppLogger.info('RouteProvider: Destination location set to $address');
    notifyListeners();
  }

  // Set the departure time and recalculate route if needed
  void setDepartureTime(DateTime time) {
    // Clear any cached route data to force recalculation
    routeData = null;

    departureTime = time;
    AppLogger.info('RouteProvider: Departure time set to $time');

    // Update planned times for all stops
    _updateStopTimes();

    notifyListeners();

    // If we have a start and destination, immediately recalculate the route
    if (startLocation != null && destinationLocation != null) {
      calculateRoute();
    }
  }

  // Add a stop
  void addStop(Stop stop) {
    stops.add(stop);
    stops.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
    AppLogger.info('RouteProvider: Added stop ${stop.label}');
    notifyListeners();

    // Recalculate route if we have locations
    if (startLocation != null && destinationLocation != null) {
      calculateRoute();
    }
  }

  // Update a stop
  void updateStop(Stop updatedStop) {
    final index = stops.indexWhere((s) => s.id == updatedStop.id);
    if (index >= 0) {
      stops[index] = updatedStop;
      stops.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
      AppLogger.info('RouteProvider: Updated stop ${updatedStop.label}');
      notifyListeners();

      // Recalculate route
      if (startLocation != null && destinationLocation != null) {
        calculateRoute();
      }
    }
  }

  // Remove a stop
  void removeStop(String stopId) {
    final index = stops.indexWhere((s) => s.id == stopId);
    if (index >= 0) {
      final stop = stops.removeAt(index);
      AppLogger.info('RouteProvider: Removed stop ${stop.label}');
      notifyListeners();

      // Recalculate route
      if (startLocation != null && destinationLocation != null) {
        calculateRoute();
      }
    }
  }

  // Add a meal stop
  void addMealStop(StopType mealType) {
    final stop = Stop.createMealStop(
      mealType: mealType,
      departureTime: departureTime,
    );
    addStop(stop);
  }

  // Add a custom stop
  void addCustomStop(String label) {
    final stop = Stop.createCustomStop(
      label: label,
      departureTime: departureTime,
    );
    addStop(stop);
  }

  // Shift all stop times by a duration
  void shiftAllStopTimes(Duration offset) {
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      stops[i] = stop.copyWith(plannedTime: stop.plannedTime.add(offset));
    }
    AppLogger.info('RouteProvider: Shifted all stop times by $offset');
    notifyListeners();
  }

  // Update stop times based on departure time
  void _updateStopTimes() {
    // This is a simplified version that keeps the relative timing
    // A more sophisticated version would use route data to calculate exact timings
    final originalDeparture =
        stops.isEmpty
            ? departureTime
            : stops.first.plannedTime.subtract(Duration(hours: 3));

    final difference = departureTime.difference(originalDeparture);

    if (difference.inSeconds != 0) {
      shiftAllStopTimes(difference);
    }
  }

  // Calculate the estimated arrival time
  DateTime get estimatedArrivalTime {
    if (routeData == null) {
      return departureTime;
    }

    // Start with departure time
    DateTime arrival = departureTime;

    // Add driving duration
    arrival = arrival.add(routeData!.duration);

    // Add dwell time for all stops
    for (final stop in stops) {
      arrival = arrival.add(stop.dwellTime);
    }

    return arrival;
  }

  // Get formatted arrival time (with "+1 day" if needed)
  String get formattedArrivalTime {
    final arrival = estimatedArrivalTime;
    final departureDayStart = DateTime(
      departureTime.year,
      departureTime.month,
      departureTime.day,
    );
    final arrivalDayStart = DateTime(arrival.year, arrival.month, arrival.day);

    final daysDifference = arrivalDayStart.difference(departureDayStart).inDays;

    final hour = arrival.hour;
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeString = '$hourDisplay:$minute $period';

    if (daysDifference > 0) {
      return '$timeString (+$daysDifference ${daysDifference == 1 ? 'day' : 'days'})';
    } else {
      return timeString;
    }
  }

  // Calculate route
  Future<bool> calculateRoute() async {
    if (startLocation == null || destinationLocation == null) {
      errorMessage = 'Start and destination locations are required';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Convert stops to waypoints
      final waypoints =
          stops
              .where((stop) => stop.location != null)
              .map((stop) => stop.location!)
              .toList();

      final result = await _directionsService.getDirections(
        origin: startLocation!,
        destination: destinationLocation!,
        waypoints: waypoints,
        departureTime: departureTime,
      );

      if (result != null) {
        routeData = result;
        errorMessage = null;
        AppLogger.info(
          'RouteProvider: Route calculated successfully with duration: ${result.formattedDuration}',
        );
      } else {
        errorMessage = 'Failed to calculate route';
        AppLogger.warning('RouteProvider: Failed to calculate route');
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      AppLogger.severe('RouteProvider: Error calculating route: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return errorMessage == null;
  }

  // Clear the route
  void clearRoute() {
    startAddress = null;
    destinationAddress = null;
    startLocation = null;
    destinationLocation = null;
    stops.clear();
    routeData = null;
    errorMessage = null;
    AppLogger.info('RouteProvider: Route cleared');
    notifyListeners();
  }

  // Optimize departure time
  Future<DateTime?> findOptimalDepartureTime() async {
    if (startLocation == null || destinationLocation == null) {
      return null;
    }

    final waypoints =
        stops
            .where((stop) => stop.location != null)
            .map((stop) => stop.location!)
            .toList();

    final optimizer = TravelTimeOptimizer();

    final optimalTime = await optimizer.findOptimalDepartureTime(
      origin: startLocation!,
      destination: destinationLocation!,
      waypoints: waypoints,
      baseTime: DateTime.now(),
    );

    if (optimalTime != null) {
      AppLogger.info(
        'RouteProvider: Found optimal departure time: $optimalTime',
      );
    }

    return optimalTime;
  }

  // Add meal stops at appropriate times
  void addMealStopsBasedOnDeparture() {
    // Clear existing meal stops
    stops.removeWhere(
      (stop) =>
          stop.type == StopType.breakfast ||
          stop.type == StopType.lunch ||
          stop.type == StopType.dinner,
    );

    // Add breakfast stop (approximately 3 hours after departure or at 8 AM)
    final breakfastTime =
        departureTime.hour < 5
            ? DateTime(
              departureTime.year,
              departureTime.month,
              departureTime.day,
              8, // 8 AM
              0,
            )
            : departureTime.add(const Duration(hours: 3));

    addStop(
      Stop.createMealStop(
        mealType: StopType.breakfast,
        departureTime: departureTime,
        offset: breakfastTime.difference(departureTime),
      ),
    );

    // Add lunch stop (approximately 7 hours after departure or at 12 PM)
    final lunchTime =
        departureTime.hour < 5
            ? DateTime(
              departureTime.year,
              departureTime.month,
              departureTime.day,
              12, // 12 PM
              0,
            )
            : departureTime.add(const Duration(hours: 7));

    addStop(
      Stop.createMealStop(
        mealType: StopType.lunch,
        departureTime: departureTime,
        offset: lunchTime.difference(departureTime),
      ),
    );

    // Add dinner stop (approximately 12 hours after departure or at 6 PM)
    final dinnerTime =
        departureTime.hour < 6
            ? DateTime(
              departureTime.year,
              departureTime.month,
              departureTime.day,
              18, // 6 PM
              0,
            )
            : departureTime.add(const Duration(hours: 12));

    addStop(
      Stop.createMealStop(
        mealType: StopType.dinner,
        departureTime: departureTime,
        offset: dinnerTime.difference(departureTime),
      ),
    );

    // Sort stops by time
    stops.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));

    notifyListeners();

    // Recalculate route with the new stops
    if (startLocation != null && destinationLocation != null) {
      calculateRoute();
    }
  }
}
