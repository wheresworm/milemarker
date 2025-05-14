import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/place.dart' as place_model;
import 'directions_service.dart';
import 'places_service.dart';

class FoodStopService {
  final PlacesService placesService;
  final DirectionsService directionsService;

  FoodStopService({
    required this.placesService,
    required this.directionsService,
  });

  // Find meal options along route at specified time
  Future<List<FoodSuggestion>> findMealOptions({
    required route_model.Route route,
    required FoodStop mealStop,
    required DateTime tripDate,
  }) async {
    // Calculate where you'll be at meal time
    final mealTime = DateTime(
      tripDate.year,
      tripDate.month,
      tripDate.day,
      mealStop.timeWindow?.preferred.hour ?? 12,
      mealStop.timeWindow?.preferred.minute ?? 0,
    );

    final mealLocation = route.getLocationAtTime(mealTime);
    if (mealLocation == null) return [];

    // Search for restaurants near that location
    final places = await placesService.searchNearby(
      location: mealLocation,
      radius: mealStop.maxDetour.inMinutes * 1000, // rough conversion to meters
      types: [place_model.PlaceType.restaurant],
      keyword: _getSearchKeyword(mealStop),
    );

    // Filter and calculate detours
    final suggestions = <FoodSuggestion>[];

    for (final place in places) {
      // Check if it matches preferences
      if (!_matchesPreferences(place, mealStop.preferences)) {
        continue;
      }

      // Check if open at meal time
      if (place.openingHours != null &&
          !place.openingHours!.isOpenAt(mealTime)) {
        continue;
      }

      // Calculate detour
      final detour = await _calculateDetour(
        route: route,
        stopLocation: place.location,
        arrivalTime: mealTime,
      );

      if (detour <= mealStop.maxDetour) {
        // Fix: Ensure place.priceLevel is properly cast to PriceLevel
        final priceLevel = place.priceLevel is PriceLevel
            ? place.priceLevel as PriceLevel
            : PriceLevel.moderate;

        suggestions.add(FoodSuggestion(
          restaurant: place,
          detour: detour,
          rating: place.rating ?? 0.0,
          currentlyOpen: place.openingHours?.isOpenNow ?? true,
          priceLevel: priceLevel,
          popularItems: [],
          distance: _calculateDistance(mealLocation, place.location),
        ));
      }
    }

    // Sort by combination of rating and detour
    suggestions.sort((a, b) {
      final aScore = a.rating - (a.detour.inMinutes / 10);
      final bScore = b.rating - (b.detour.inMinutes / 10);
      return bScore.compareTo(aScore);
    });

    return suggestions.take(5).toList();
  }

  // Suggest meal times based on trip duration and departure
  List<FoodStop> suggestMealTimes(route_model.Route route) {
    final suggestions = <FoodStop>[];
    final departure = route.departureTime;
    final duration = route.totalDuration;

    // Breakfast: If departing before 9 AM and trip is > 2 hours
    if (departure.hour < 9 && duration.inHours >= 2) {
      final breakfastTime = departure.add(const Duration(hours: 2));
      suggestions.add(FoodStop(
        id: 'breakfast_${DateTime.now().millisecondsSinceEpoch}',
        location: route.getLocationAtTime(breakfastTime) ?? route.origin,
        name: 'Breakfast Stop',
        order: _findOrderPosition(route, breakfastTime),
        mealType: MealType.breakfast,
        preferences: [
          FoodPreference(
            category: 'fast-food',
            chains: ['McDonald\'s', 'Dunkin\'', 'Starbucks'],
          ),
        ],
        timeWindow: TimeWindow(
          earliest: breakfastTime.subtract(const Duration(minutes: 30)),
          latest: breakfastTime.add(const Duration(minutes: 30)),
          preferred: breakfastTime,
        ),
      ));
    }

    // Lunch: If trip spans 11 AM - 2 PM
    final lunchStart =
        DateTime(departure.year, departure.month, departure.day, 11, 0);
    final lunchEnd =
        DateTime(departure.year, departure.month, departure.day, 14, 0);

    if (_tripSpansTime(route, lunchStart, lunchEnd)) {
      final lunchTime =
          DateTime(departure.year, departure.month, departure.day, 12, 30);
      suggestions.add(FoodStop(
        id: 'lunch_${DateTime.now().millisecondsSinceEpoch}',
        location: route.getLocationAtTime(lunchTime) ?? route.origin,
        name: 'Lunch Stop',
        order: _findOrderPosition(route, lunchTime),
        mealType: MealType.lunch,
        preferences: [
          FoodPreference(category: 'any'),
        ],
        timeWindow: TimeWindow(
          earliest: lunchTime.subtract(const Duration(hours: 1)),
          latest: lunchTime.add(const Duration(hours: 1)),
          preferred: lunchTime,
        ),
      ));
    }

    // Dinner: If trip spans 5 PM - 8 PM
    final dinnerStart =
        DateTime(departure.year, departure.month, departure.day, 17, 0);
    final dinnerEnd =
        DateTime(departure.year, departure.month, departure.day, 20, 0);

    if (_tripSpansTime(route, dinnerStart, dinnerEnd)) {
      final dinnerTime =
          DateTime(departure.year, departure.month, departure.day, 18, 0);
      suggestions.add(FoodStop(
        id: 'dinner_${DateTime.now().millisecondsSinceEpoch}',
        location: route.getLocationAtTime(dinnerTime) ?? route.origin,
        name: 'Dinner Stop',
        order: _findOrderPosition(route, dinnerTime),
        mealType: MealType.dinner,
        preferences: [
          FoodPreference(category: 'sit-down'),
        ],
        timeWindow: TimeWindow(
          earliest: dinnerTime.subtract(const Duration(hours: 1)),
          latest: dinnerTime.add(const Duration(hours: 1)),
          preferred: dinnerTime,
        ),
      ));
    }

    return suggestions;
  }

  String _getSearchKeyword(FoodStop mealStop) {
    // Build search keyword from preferences
    final keywords = <String>[];

    for (final pref in mealStop.preferences) {
      if (pref.category != null) keywords.add(pref.category!);
      keywords.addAll(pref.chains);
      keywords.addAll(pref.cuisines);
    }

    if (keywords.isEmpty) {
      switch (mealStop.mealType) {
        case MealType.breakfast:
          return 'breakfast restaurant';
        case MealType.lunch:
          return 'lunch restaurant';
        case MealType.dinner:
          return 'dinner restaurant';
        case MealType.snack:
          return 'coffee shop';
      }
    }

    return keywords.join(' ');
  }

  bool _matchesPreferences(
      place_model.Place place, List<FoodPreference> preferences) {
    if (preferences.isEmpty) return true;

    for (final pref in preferences) {
      // Check chains
      if (pref.chains.isNotEmpty) {
        for (final chain in pref.chains) {
          if (place.name.toLowerCase().contains(chain.toLowerCase())) {
            return true;
          }
        }
      }

      // Check price level
      if (pref.priceLevel != null) {
        // Fix: Compare properly with type checking
        final placePriceLevel = place.priceLevel is PriceLevel
            ? place.priceLevel as PriceLevel
            : null;

        if (placePriceLevel == pref.priceLevel) {
          return true;
        }
      }

      // Check category
      if (pref.category == 'any') return true;
    }

    return false;
  }

  Future<Duration> _calculateDetour({
    required route_model.Route route,
    required LatLng stopLocation,
    required DateTime arrivalTime,
  }) async {
    // Simple approximation - in production, use actual directions API
    final directDistance = _calculateDistance(
      route.getLocationAtTime(arrivalTime) ?? route.origin,
      stopLocation,
    );

    // Assume average detour adds 2x the direct distance in time
    // At 30 mph average speed in towns
    return Duration(minutes: (directDistance * 2 / 30 * 60).round());
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

  bool _tripSpansTime(route_model.Route route, DateTime start, DateTime end) {
    final tripEnd = route.departureTime.add(route.totalDuration);
    return route.departureTime.isBefore(end) && tripEnd.isAfter(start);
  }

  int _findOrderPosition(route_model.Route route, DateTime time) {
    // Find appropriate position in stop order based on time
    for (int i = 0; i < route.stops.length - 1; i++) {
      final stop = route.stops[i];
      final nextStop = route.stops[i + 1];

      if (stop.timeWindow != null && nextStop.timeWindow != null) {
        if (time.isAfter(stop.timeWindow!.preferred) &&
            time.isBefore(nextStop.timeWindow!.preferred)) {
          return i + 1;
        }
      }
    }

    return route.stops.length - 1;
  }
}

class QuickFoodOptions {
  static final FoodPreference fastBreakfast = FoodPreference(
    category: 'fast-food',
    chains: ['McDonald\'s', 'Dunkin\'', 'Starbucks', 'Chick-fil-A'],
  );

  static final FoodPreference roadTripClassics = FoodPreference(
    category: 'any',
    chains: ['Cracker Barrel', 'Waffle House', 'Denny\'s', 'IHOP'],
  );

  static final FoodPreference healthyOptions = FoodPreference(
    category: 'healthy',
    cuisines: ['Salad', 'Mediterranean', 'Vegetarian', 'Vegan'],
  );

  static final FoodPreference quickLunch = FoodPreference(
    category: 'fast-food',
    chains: ['Subway', 'Chipotle', 'Panera', 'Jimmy John\'s'],
  );

  static final FoodPreference familyFriendly = FoodPreference(
    category: 'family',
    chains: ['Applebee\'s', 'Olive Garden', 'Red Robin', 'TGI Friday\'s'],
  );
}
