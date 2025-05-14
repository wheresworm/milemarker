import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import '../models/fuel_stop.dart';
import '../models/stop.dart';
import '../models/place.dart';
import 'places_service.dart';

class FuelPlanningService {
  final PlacesService placesService;
  static const String _gasPriceApiUrl =
      'https://api.gasbuddy.com/v1/prices'; // Example

  FuelPlanningService({required this.placesService});

  // Plan fuel stops based on vehicle and route
  Future<List<FuelStop>> planFuelStops({
    required route_model.Route route,
    required Vehicle vehicle,
    required double currentFuelLevel, // percentage
  }) async {
    final suggestions = <FuelStop>[];

    // Calculate fuel consumption
    final totalMiles = route.totalDistance;
    final mpg = vehicle.mpg;
    final tankSize = vehicle.tankSize;

    // Current fuel in gallons
    double currentFuel = tankSize * (currentFuelLevel / 100);
    double milesDriven = 0;

    // Never go below 1/4 tank (25%)
    const double minFuelLevel = 0.25;
    final minFuelGallons = tankSize * minFuelLevel;

    // Check fuel level at various points along route
    for (final stop in route.stops) {
      // Calculate fuel consumed to reach this stop
      if (milesDriven > 0) {
        final fuelConsumed = milesDriven / mpg;
        currentFuel -= fuelConsumed;

        // Need fuel if we'll go below minimum
        final milesRemaining = route.totalDistance - milesDriven;
        final fuelNeededForRest = milesRemaining / mpg;

        if (currentFuel - fuelNeededForRest < minFuelGallons ||
            currentFuel < minFuelGallons * 1.5) {
          // Find gas stations near this location
          final fuelStops = await _findNearbyGasStations(
            stop.location,
            vehicle.preferredBrands,
            vehicle.requiresDiesel,
          );

          if (fuelStops.isNotEmpty) {
            suggestions.add(fuelStops.first);
            currentFuel = tankSize * 0.9; // Assume 90% fill
          }
        }
      }

      // Calculate distance to next stop
      final nextStopIndex = route.stops.indexOf(stop) + 1;
      if (nextStopIndex < route.stops.length) {
        final nextStop = route.stops[nextStopIndex];
        milesDriven += _calculateDistance(stop.location, nextStop.location);
      }
    }

    return suggestions;
  }

  // Find cheapest gas along route
  Future<List<FuelStop>> findCheapestGas({
    required route_model.Route route,
    required Vehicle vehicle,
    int maxDetourMinutes = 10,
  }) async {
    final gasStations = <FuelStop>[];

    // Sample points along route (every 50 miles)
    const sampleInterval = 50.0;
    final numSamples = (route.totalDistance / sampleInterval).ceil();

    for (int i = 0; i <= numSamples; i++) {
      final progress = i / numSamples;
      final sampleTime = route.departureTime.add(
        Duration(seconds: (route.totalDuration.inSeconds * progress).round()),
      );

      final location = route.getLocationAtTime(sampleTime);
      if (location == null) continue;

      final nearbyStations = await _findNearbyGasStations(
        location,
        vehicle.preferredBrands,
        vehicle.requiresDiesel,
      );

      gasStations.addAll(nearbyStations);
    }

    // Sort by price
    gasStations.sort((a, b) => a.pricePerGallon.compareTo(b.pricePerGallon));

    // Return top 5 cheapest
    return gasStations.take(5).toList();
  }

  // Find gas stations near a location
  Future<List<FuelStop>> _findNearbyGasStations(
    LatLng location,
    List<FuelBrand> preferredBrands,
    bool requiresDiesel,
  ) async {
    // Search for gas stations
    final places = await placesService.searchNearby(
      location: location,
      radius: 16000, // 10 miles
      types: [PlaceType.gasStation],
    );

    final fuelStops = <FuelStop>[];

    for (final place in places) {
      // Parse brand from name
      final brand = _parseBrand(place.name);

      // Skip if not preferred brand
      if (preferredBrands.isNotEmpty &&
          preferredBrands.contains(FuelBrand.any) == false &&
          !preferredBrands.contains(brand)) {
        continue;
      }

      // Get current gas price (mock for now)
      final price = await _getGasPrice(place.id, requiresDiesel);

      // Check amenities
      final amenities = _parseAmenities(place);

      fuelStops.add(FuelStop(
        id: place.id,
        location: place.location,
        name: place.name,
        order: 0, // Will be set later
        brand: brand,
        pricePerGallon: price,
        amenities: amenities,
        detour: Duration.zero, // Calculate if needed
        hasDiesel: true, // Most stations have diesel
        priceUpdated: DateTime.now(),
      ));
    }

    return fuelStops;
  }

  FuelBrand _parseBrand(String name) {
    final lowercaseName = name.toLowerCase();

    if (lowercaseName.contains('shell')) return FuelBrand.shell;
    if (lowercaseName.contains('chevron')) return FuelBrand.chevron;
    if (lowercaseName.contains('exxon')) return FuelBrand.exxon;
    if (lowercaseName.contains('bp')) return FuelBrand.bp;
    if (lowercaseName.contains('mobil')) return FuelBrand.mobil;
    if (lowercaseName.contains('speedway')) return FuelBrand.speedway;
    if (lowercaseName.contains('wawa')) return FuelBrand.wawa;
    if (lowercaseName.contains('sheetz')) return FuelBrand.sheetz;
    if (lowercaseName.contains('costco')) return FuelBrand.costco;
    if (lowercaseName.contains('sam')) return FuelBrand.sams;

    return FuelBrand.any;
  }

  List<String> _parseAmenities(Place place) {
    final amenities = <String>[];

    // Common gas station amenities
    final possibleAmenities = [
      'restroom',
      'convenience store',
      'atm',
      'air pump',
      'car wash',
      'restaurant',
    ];

    // Check place amenities list
    amenities.addAll(place.amenities);

    // Default amenities most gas stations have
    if (amenities.isEmpty) {
      amenities.addAll(['restroom', 'convenience store']);
    }

    return amenities;
  }

  Future<double> _getGasPrice(String placeId, bool diesel) async {
    // In production, this would call a gas price API
    // For now, return mock prices based on random variation
    final basePrice = diesel ? 3.80 : 3.20;
    final variation = Random().nextDouble() * 0.60 - 0.30; // +/- $0.30
    return basePrice + variation;
  }

  double _calculateDistance(LatLng from, LatLng to) {
    // Haversine formula for distance
    const double earthRadius = 3959; // miles
    final double dLat = _toRadians(to.latitude - from.latitude);
    final double dLon = _toRadians(to.longitude - from.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

class Vehicle {
  final String id;
  final String name;
  final VehicleType type;
  final double tankSize; // gallons
  final double mpg;
  final double currentFuelLevel; // percentage
  final List<FuelBrand> preferredBrands;
  final bool requiresDiesel;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.tankSize,
    required this.mpg,
    required this.currentFuelLevel,
    this.preferredBrands = const [],
    this.requiresDiesel = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'tankSize': tankSize,
        'mpg': mpg,
        'currentFuelLevel': currentFuelLevel,
        'preferredBrands': preferredBrands.map((b) => b.toString()).toList(),
        'requiresDiesel': requiresDiesel,
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'],
        name: map['name'],
        type: VehicleType.values.firstWhere((t) => t.toString() == map['type']),
        tankSize: map['tankSize'],
        mpg: map['mpg'],
        currentFuelLevel: map['currentFuelLevel'],
        preferredBrands: (map['preferredBrands'] as List)
            .map((b) => FuelBrand.values.firstWhere((fb) => fb.toString() == b))
            .toList(),
        requiresDiesel: map['requiresDiesel'],
      );
}

enum VehicleType { car, suv, truck, van, rv, motorcycle }
