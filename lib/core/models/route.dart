import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';
import 'directions.dart';

enum RouteOptimization {
  fastest,
  shortest,
  fuelEfficient,
  scenic,
}

class Route {
  final String id;
  final String name;
  final List<Stop> stops;
  final DateTime departureTime;
  final RouteOptimization optimization;
  final Directions? directions;
  final RouteStats? stats;
  final List<WeatherInfo> weatherAlerts;
  final List<ConstructionAlert> constructionAlerts;
  final Map<String, dynamic> metadata;

  Route({
    required this.id,
    required this.name,
    required this.stops,
    required this.departureTime,
    this.optimization = RouteOptimization.fastest,
    this.directions,
    this.stats,
    this.weatherAlerts = const [],
    this.constructionAlerts = const [],
    this.metadata = const {},
  });

  LatLng get origin => stops.first.location;
  LatLng get destination => stops.last.location;
  List<LatLng> get waypoints => stops
      .skip(1)
      .take(stops.length - 2)
      .map((stop) => stop.location)
      .toList();

  Duration get totalDuration => stats?.totalDuration ?? Duration.zero;
  double get totalDistance => stats?.totalDistance ?? 0.0;

  // Get location at specific time during trip
  LatLng? getLocationAtTime(DateTime time) {
    if (directions == null || time.isBefore(departureTime)) return null;

    final elapsed = time.difference(departureTime);
    double elapsedDistance = 0;

    // Find which segment we're in
    for (final leg in directions!.legs) {
      if (elapsed <= leg.duration) {
        // We're in this leg
        final progress = elapsed.inSeconds / leg.duration.inSeconds;
        return _interpolateLocation(
          leg.startLocation,
          leg.endLocation,
          progress,
        );
      }
      elapsedDistance += leg.distance;
    }

    return destination;
  }

  LatLng _interpolateLocation(LatLng start, LatLng end, double progress) {
    final lat = start.latitude + (end.latitude - start.latitude) * progress;
    final lng = start.longitude + (end.longitude - start.longitude) * progress;
    return LatLng(lat, lng);
  }

  Route copyWith({
    String? name,
    List<Stop>? stops,
    DateTime? departureTime,
    RouteOptimization? optimization,
    Directions? directions,
    RouteStats? stats,
  }) =>
      Route(
        id: id,
        name: name ?? this.name,
        stops: stops ?? this.stops,
        departureTime: departureTime ?? this.departureTime,
        optimization: optimization ?? this.optimization,
        directions: directions ?? this.directions,
        stats: stats ?? this.stats,
        weatherAlerts: weatherAlerts,
        constructionAlerts: constructionAlerts,
        metadata: metadata,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'stops': stops.map((s) => s.toMap()).toList(),
        'departureTime': departureTime.toIso8601String(),
        'optimization': optimization.toString(),
        'directions': directions?.toMap(),
        'stats': stats?.toMap(),
        'metadata': metadata,
      };
}

class RouteStats {
  final Duration totalDuration;
  final double totalDistance; // miles
  final double estimatedFuelCost;
  final double estimatedTolls;
  final int numberOfStops;
  final Map<MealType, int> mealStops;
  final int fuelStops;
  final List<StateInfo> statesTraversed;

  RouteStats({
    required this.totalDuration,
    required this.totalDistance,
    required this.estimatedFuelCost,
    required this.estimatedTolls,
    required this.numberOfStops,
    required this.mealStops,
    required this.fuelStops,
    required this.statesTraversed,
  });

  Map<String, dynamic> toMap() => {
        'totalDuration': totalDuration.inSeconds,
        'totalDistance': totalDistance,
        'estimatedFuelCost': estimatedFuelCost,
        'estimatedTolls': estimatedTolls,
        'numberOfStops': numberOfStops,
        'mealStops': mealStops.map((k, v) => MapEntry(k.toString(), v)),
        'fuelStops': fuelStops,
        'statesTraversed': statesTraversed.map((s) => s.toMap()).toList(),
      };
}

class StateInfo {
  final String name;
  final String abbreviation;
  final double milesInState;
  final Duration timeInState;
  final int speedLimit;

  StateInfo({
    required this.name,
    required this.abbreviation,
    required this.milesInState,
    required this.timeInState,
    required this.speedLimit,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'abbreviation': abbreviation,
        'milesInState': milesInState,
        'timeInState': timeInState.inSeconds,
        'speedLimit': speedLimit,
      };
}

class WeatherInfo {
  final DateTime time;
  final LatLng location;
  final String condition;
  final double temperature;
  final double precipitation;
  final int visibility; // miles
  final WeatherSeverity severity;

  WeatherInfo({
    required this.time,
    required this.location,
    required this.condition,
    required this.temperature,
    required this.precipitation,
    required this.visibility,
    required this.severity,
  });
}

enum WeatherSeverity { clear, moderate, severe }

class ConstructionAlert {
  final LatLng location;
  final String description;
  final Duration expectedDelay;
  final DateTime startDate;
  final DateTime? endDate;

  ConstructionAlert({
    required this.location,
    required this.description,
    required this.expectedDelay,
    required this.startDate,
    this.endDate,
  });
}
