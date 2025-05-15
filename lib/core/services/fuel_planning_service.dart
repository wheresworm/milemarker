import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/fuel_stop.dart';
import '../models/user_route.dart';
import '../models/vehicle.dart';
import './places_service.dart';

class FuelPlanningService {
  final PlacesService _placesService;

  FuelPlanningService({
    required PlacesService placesService,
  }) : _placesService = placesService;

  Future<List<FuelStop>> suggestFuelStops({
    required UserRoute route,
    required Vehicle vehicle,
    required double currentFuelLevel,
    double maxDetourDistance = 5.0, // km
  }) async {
    final fuelStops = <FuelStop>[];

    // Calculate fuel consumption per km
    final fuelConsumptionPerKm = vehicle.fuelConsumption / 100;

    // Calculate range with current fuel
    double remainingRange = currentFuelLevel / fuelConsumptionPerKm;

    // Never let fuel drop below 25% of tank capacity
    final minFuelLevel = vehicle.tankCapacity * 0.25;
    final usableRange =
        (currentFuelLevel - minFuelLevel) / fuelConsumptionPerKm;

    double coveredDistance = 0;

    // Go through the route and find where we need fuel
    for (int i = 0; i < route.polylinePoints.length - 1; i++) {
      final segment = _calculateDistance(
        route.polylinePoints[i],
        route.polylinePoints[i + 1],
      );

      if (coveredDistance + segment > usableRange) {
        // Need fuel before this segment
        final fuelStopLocation = route.polylinePoints[i];

        // Search for gas stations near this point
        final gasStations = await _placesService.searchPlaces(
          'gas station',
          location: fuelStopLocation,
          radiusMeters: (maxDetourDistance * 1000).round(),
        );

        if (gasStations.isNotEmpty) {
          final station = gasStations.first;

          // Calculate how much fuel is needed
          final fuelUsedToHere = coveredDistance * fuelConsumptionPerKm;
          final fuelLevelAtStop = currentFuelLevel - fuelUsedToHere;
          final gallonsNeeded = vehicle.tankCapacity - fuelLevelAtStop;

          final fuelStop = FuelStop(
            id: 'fuel_${DateTime.now().millisecondsSinceEpoch}',
            name: station.name,
            location: station.location,
            order: i,
            placeId: station.placeId,
            fuelLevel: fuelLevelAtStop,
            gallonsNeeded: gallonsNeeded,
            fuelType: vehicle.preferredFuelType,
            currentPrice: 3.50, // Placeholder price
            brand: _extractBrand(station.name),
            estimatedDuration: const Duration(minutes: 10),
          );

          fuelStops.add(fuelStop);

          // Reset for next segment
          coveredDistance = 0;
          remainingRange =
              (vehicle.tankCapacity - minFuelLevel) / fuelConsumptionPerKm;
        }
      }

      coveredDistance += segment;
      remainingRange -= segment;
    }

    return fuelStops;
  }

  String _extractBrand(String stationName) {
    final brands = [
      'Shell',
      'Chevron',
      'BP',
      'Exxon',
      'Mobil',
      'Texaco',
      'Sunoco',
      'Marathon',
      'Circle K',
      '7-Eleven',
    ];

    for (final brand in brands) {
      if (stationName.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }

    return stationName.split(' ').first;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km
    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLat =
        (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLng =
        (point2.longitude - point1.longitude) * (3.14159 / 180);

    final double a = (Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)) +
        (Math.cos(lat1Rad) *
            Math.cos(lat2Rad) *
            Math.sin(deltaLng / 2) *
            Math.sin(deltaLng / 2));

    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Add method to find specific fuel brands
  Future<List<FuelStop>> findPreferredBrandStations({
    required LatLng location,
    required String brand,
    double radiusKm = 10.0,
  }) async {
    final results = await _placesService.searchPlaces(
      '$brand gas station',
      location: location,
      radiusMeters: (radiusKm * 1000).round(),
    );

    return results
        .map((place) => FuelStop(
              id: 'fuel_${place.placeId}',
              name: place.name,
              location: place.location,
              order: 0,
              placeId: place.placeId,
              fuelType: 'regular',
              currentPrice: 3.50, // Placeholder
              brand: brand,
              estimatedDuration: const Duration(minutes: 10),
            ))
        .toList();
  }
}
