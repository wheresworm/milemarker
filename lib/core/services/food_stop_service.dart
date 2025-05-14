import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/food_stop.dart';
import '../models/meal_preferences.dart';
import '../models/place.dart';
import '../models/time_window.dart';
import '../models/user_route.dart';
import 'places_service.dart';

class FoodStopService {
  final PlacesService _placesService;

  FoodStopService({required PlacesService placesService})
      : _placesService = placesService;

  Future<List<FoodStop>> suggestMealStops({
    required UserRoute route,
    required MealPreferences preferences,
  }) async {
    final mealStops = <FoodStop>[];
    final tripDuration = route.totalDuration;
    final departureTime = route.departureTime ?? DateTime.now();

    // Determine which meals fall within the trip
    final meals = _getMealsForTrip(departureTime, tripDuration);

    for (final meal in meals) {
      // Calculate when we'll be hungry (meal time window)
      final mealTimeWindow = _getMealTimeWindow(meal, departureTime);

      // Find position on route at meal time
      final positionAtMealTime = _getPositionAtTime(
        route,
        mealTimeWindow.preferred!.start,
        departureTime,
      );

      if (positionAtMealTime != null) {
        // Search for restaurants near this position
        final nearbyRestaurants = await _searchRestaurantsNearPosition(
          position: positionAtMealTime,
          preferences: preferences,
          mealType: meal,
          maxDetour: preferences.maxDetourDistance ?? 5000,
        );

        // Filter and rank restaurants
        final rankedRestaurants = _rankRestaurants(
          restaurants: nearbyRestaurants,
          preferences: preferences,
          isOpenAt: mealTimeWindow.preferred!.start,
        );

        if (rankedRestaurants.isNotEmpty) {
          final bestOption = rankedRestaurants.first;

          mealStops.add(FoodStop(
            name: '${meal.name} - ${bestOption.name}',
            location: bestOption.location,
            placeId: bestOption.placeId,
            mealType: meal,
            cuisineType: _getCuisineType(bestOption),
            rating: bestOption.rating,
            priceLevel: bestOption.priceLevel,
            timeWindow: mealTimeWindow,
            order: route.stops.length + mealStops.length,
          ));
        }
      }
    }

    return mealStops;
  }

  List<MealType> _getMealsForTrip(
      DateTime departureTime, Duration tripDuration) {
    final meals = <MealType>[];
    final arrivalTime = departureTime.add(tripDuration);

    // Check each meal time
    for (final meal in MealType.values) {
      final mealTime = _getDefaultMealTime(meal, departureTime);

      if (mealTime.isAfter(departureTime) && mealTime.isBefore(arrivalTime)) {
        meals.add(meal);
      }
    }

    return meals;
  }

  TimeWindow _getMealTimeWindow(MealType meal, DateTime departureTime) {
    final baseTime = _getDefaultMealTime(meal, departureTime);

    return TimeWindow(
      earliest: baseTime.subtract(const Duration(hours: 1)),
      preferred: TimeRange(
        start: baseTime.subtract(const Duration(minutes: 30)),
        end: baseTime.add(const Duration(minutes: 30)),
      ),
      latest: baseTime.add(const Duration(hours: 1)),
    );
  }

  DateTime _getDefaultMealTime(MealType meal, DateTime date) {
    switch (meal) {
      case MealType.breakfast:
        return DateTime(date.year, date.month, date.day, 8, 0);
      case MealType.lunch:
        return DateTime(date.year, date.month, date.day, 12, 30);
      case MealType.dinner:
        return DateTime(date.year, date.month, date.day, 18, 30);
    }
  }

  LatLng? _getPositionAtTime(
    UserRoute route,
    DateTime targetTime,
    DateTime departureTime,
  ) {
    final elapsed = targetTime.difference(departureTime);
    final progress = elapsed.inSeconds / route.totalDuration.inSeconds;

    if (progress < 0 || progress > 1) return null;

    // Interpolate position along route
    final totalPoints = route.polylinePoints.length;
    final targetIndex = (totalPoints * progress).floor();

    if (targetIndex >= totalPoints - 1) {
      return route.polylinePoints.last;
    }

    return route.polylinePoints[targetIndex];
  }

  Future<List<Place>> _searchRestaurantsNearPosition({
    required LatLng position,
    required MealPreferences preferences,
    required MealType mealType,
    required double maxDetour,
  }) async {
    // Build search query based on preferences
    String query = 'restaurant';

    if (preferences.cuisineTypes != null &&
        preferences.cuisineTypes!.isNotEmpty) {
      query = '${preferences.cuisineTypes!.first} restaurant';
    }

    final results = await _placesService.searchPlaces(
      query: query,
      location: position,
      radiusMeters: maxDetour,
      type: PlaceType.restaurant,
    );

    // Filter out fast food if needed
    if (preferences.avoidFastFood) {
      results.removeWhere((place) =>
          place.name.toLowerCase().contains('mcdonald') ||
          place.name.toLowerCase().contains('burger king') ||
          place.name.toLowerCase().contains('wendy'));
    }

    // Filter by minimum rating
    results.removeWhere((place) =>
        place.rating != null && place.rating! < preferences.minRating);

    return results;
  }

  List<Place> _rankRestaurants({
    required List<Place> restaurants,
    required MealPreferences preferences,
    required DateTime isOpenAt,
  }) {
    final scored = restaurants.map((restaurant) {
      double score = 0;

      // Open at meal time
      if (restaurant.openingHours?.isOpenAt(isOpenAt) ?? false) {
        score += 2;
      }

      // Rating score
      if (restaurant.rating != null) {
        score += restaurant.rating! / 5;
      }

      // Price preference match
      if (preferences.maxPriceLevel != null && restaurant.priceLevel != null) {
        final priceScore = _getPriceLevelScore(restaurant.priceLevel!);
        final prefScore = _getPriceLevelScore(preferences.maxPriceLevel!);
        if (priceScore <= prefScore) {
          score += 1;
        }
      }

      // Distance penalty
      if (restaurant.distanceFromRoute != null) {
        score -= (restaurant.distanceFromRoute! / 5000); // Penalty per km
      }

      // Cuisine type match
      if (preferences.cuisineTypes != null && restaurant.cuisineTypes != null) {
        for (final cuisine in restaurant.cuisineTypes!) {
          if (preferences.cuisineTypes!.contains(cuisine)) {
            score += 1;
            break;
          }
        }
      }

      return MapEntry(restaurant, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  int _getPriceLevelScore(PriceLevel level) {
    switch (level) {
      case PriceLevel.cheap:
        return 1;
      case PriceLevel.moderate:
        return 2;
      case PriceLevel.expensive:
        return 3;
      case PriceLevel.veryExpensive:
        return 4;
    }
  }

  String? _getCuisineType(Place restaurant) {
    return restaurant.cuisineTypes?.isNotEmpty ?? false
        ? restaurant.cuisineTypes!.first
        : null;
  }
}
