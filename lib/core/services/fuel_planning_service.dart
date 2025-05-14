import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/fuel_stop.dart';
import '../models/place.dart';
import '../models/stop.dart';
import '../models/user_route.dart';
import '../models/vehicle_profile.dart';
import 'places_service.dart';

class FuelPlanningService {
  final PlacesService _placesService;

  FuelPlanningService({required PlacesService placesService})
      : _placesService = placesService;

  Future<List<FuelStop>> calculateFuelStops({
    required UserRoute route,
    required VehicleProfile vehicleProfile,
  }) async {
    final fuelStops = <FuelStop>[];

    // Calculate total distance needed
    final totalDistance = route.totalDistance;
    final rangePerTank = _calculateRange(vehicleProfile);

    // Never let user go below 1/4 tank
    final safeRange = rangePerTank * 0.75;

    // Calculate number of fuel stops needed
    final numStops = (totalDistance / safeRange).ceil();

    if (numStops <= 0) return fuelStops;

    // Divide route into segments
    final segmentDistance = totalDistance / (numStops + 1);
    double currentDistance = 0;

    for (int i = 0; i < numStops; i++) {
      currentDistance += segmentDistance;

      // Find point on route at this distance
      final pointOnRoute = _getPointAtDistance(
        route.polylinePoints,
        currentDistance,
        totalDistance,
      );

      if (pointOnRoute != null) {
        // Search for gas stations near this point
        final nearbyStations = await _placesService.searchAlongRoute(
          routePoints: route.polylinePoints,
          type: PlaceType.gasStation,
          maxDetourMeters: 5000,
        );

        // Filter by preferred brands if any
        final filteredStations = _filterByPreferences(
          nearbyStations,
          vehicleProfile.preferredGasStations ?? [],
        );

        // Find best station (closest to route)
        if (filteredStations.isNotEmpty) {
          final bestStation = filteredStations.reduce((a, b) =>
              (a.distanceFromRoute ?? double.infinity) <
                      (b.distanceFromRoute ?? double.infinity)
                  ? a
                  : b);

          fuelStops.add(FuelStop(
            name: bestStation.name,
            location: bestStation.location,
            placeId: bestStation.placeId,
            gallonsNeeded: vehicleProfile.tankSize * 0.75,
            order: route.stops.length + i,
          ));
        }
      }
    }

    return fuelStops;
  }

  double _calculateRange(VehicleProfile profile) {
    return profile.tankSize * profile.mpg;
  }

  LatLng? _getPointAtDistance(
    List<LatLng> points,
    double targetDistance,
    double totalDistance,
  ) {
    if (points.isEmpty) return null;

    double currentDistance = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final segmentDistance = _calculateDistance(points[i], points[i + 1]);

      if (currentDistance + segmentDistance >= targetDistance) {
        // Interpolate position on this segment
        final ratio = (targetDistance - currentDistance) / segmentDistance;

        return LatLng(
          points[i].latitude +
              (points[i + 1].latitude - points[i].latitude) * ratio,
          points[i].longitude +
              (points[i + 1].longitude - points[i].longitude) * ratio,
        );
      }

      currentDistance += segmentDistance;
    }

    return points.last;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = p1.latitude * (3.141592653589793 / 180);
    final double lat2Rad = p2.latitude * (3.141592653589793 / 180);
    final double deltaLat =
        (p2.latitude - p1.latitude) * (3.141592653589793 / 180);
    final double deltaLng =
        (p2.longitude - p1.longitude) * (3.141592653589793 / 180);

    final double a = (deltaLat / 2).sin() * (deltaLat / 2).sin() +
        lat1Rad.cos() *
            lat2Rad.cos() *
            (deltaLng / 2).sin() *
            (deltaLng / 2).sin();

    final double c = 2 * a.sqrt().asin();

    return earthRadius * c / 1609.344; // Convert to miles
  }

  List<Place> _filterByPreferences(
    List<Place> stations,
    List<String> preferredBrands,
  ) {
    if (preferredBrands.isEmpty) return stations;

    // First try to find preferred brands
    final preferredStations = stations.where((station) {
      final name = station.name.toLowerCase();
      return preferredBrands.any((brand) => name.contains(brand.toLowerCase()));
    }).toList();

    // If found, return only preferred; otherwise return all
    return preferredStations.isNotEmpty ? preferredStations : stations;
  }

  Future<List<PossibleAmenity>> suggestAmenities({
    required List<Stop> stops,
    required VehicleProfile vehicleProfile,
  }) async {
    final amenities = <PossibleAmenity>[];

    // For each fuel stop, suggest nearby amenities
    for (final stop in stops) {
      if (stop is FuelStop) {
        // Search for convenience stores, restaurants nearby
        final nearbyPlaces = await _placesService.searchPlaces(
          query: 'convenience store restaurant',
          location: stop.location,
          radiusMeters: 1000,
        );

        for (final place in nearbyPlaces) {
          amenities.add(PossibleAmenity(
            name: place.name,
            location: place.location,
            type: _getAmenityType(place.type),
            associatedStopId: stop.id,
          ));
        }
      }
    }

    return amenities;
  }

  AmenityType _getAmenityType(PlaceType placeType) {
    switch (placeType) {
      case PlaceType.restaurant:
        return AmenityType.food;
      case PlaceType.convenienceStore:
        return AmenityType.restroom;
      default:
        return AmenityType.rest;
    }
  }
}

class PossibleAmenity {
  final String name;
  final LatLng location;
  final AmenityType type;
  final String associatedStopId;

  PossibleAmenity({
    required this.name,
    required this.location,
    required this.type,
    required this.associatedStopId,
  });
}

enum AmenityType { restroom, food, rest }
