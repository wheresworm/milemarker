// lib/core/services/food_stop_service.dart
import 'dart:math';
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/place.dart';
import '../models/user_route.dart'; // Add this import
import '../services/places_service.dart';
import '../services/directions_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FoodStopService {
  final PlacesService _placesService;
  final DirectionsService _directionsService;

  FoodStopService({
    PlacesService? placesService,
    DirectionsService? directionsService,
  })  : _placesService = placesService ?? PlacesService(),
        _directionsService = directionsService ?? DirectionsService();

  Future<List<FoodSuggestion>> findMealOptions({
    required MealType mealType,
    required LatLng location,
    required DateTime targetTime,
    required List<FoodPreference> preferences,
    required Duration maxDetour,
    double searchRadius = 5000,
  }) async {
    // Get restaurant places
    final places = await _placesService.searchNearbyPlaces(
      location: location,
      radius: searchRadius.toInt(),
      type: PlaceType.restaurant,
    );

    final suggestions = <FoodSuggestion>[];

    for (final place in places) {
      if (!_matchesPreferences(place, preferences)) continue;

      final detour = await _calculateDetour(location, place.location);

      if (detour.inMinutes <= maxDetour.inMinutes) {
        suggestions.add(
          FoodSuggestion(
            place: place,
            detourMinutes: detour.inMinutes.toDouble(),
            detourMiles: _calculateDistance(location, place.location),
            matchingPreferences: _getMatchingPreferences(place, preferences),
          ),
        );
      }
    }

    suggestions.sort((a, b) {
      final aScore = a.detourMinutes + (5 - a.matchingPreferences.length) * 5;
      final bScore = b.detourMinutes + (5 - b.matchingPreferences.length) * 5;
      return aScore.compareTo(bScore);
    });

    return suggestions.take(10).toList();
  }

  Future<List<FoodSuggestion>> suggestMealStops({
    required UserRoute route,
    required DateTime departureTime,
    required List<FoodPreference> preferences,
  }) async {
    final suggestions = <FoodSuggestion>[];

    for (var stop in route.stops) {
      if (stop is FoodStop) continue;

      final mealType = _getMealTypeForTime(departureTime);
      final mealSuggestions = await findMealOptions(
        mealType: mealType,
        location: stop.location,
        targetTime: departureTime,
        preferences: preferences,
        maxDetour: const Duration(minutes: 15),
      );

      suggestions.addAll(mealSuggestions);
    }

    return suggestions;
  }

  MealType _getMealTypeForTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) return MealType.breakfast;
    if (hour >= 11 && hour < 16) return MealType.lunch;
    return MealType.dinner;
  }

  List<String> _getCuisineTypesForMeal(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return ['breakfast', 'cafe', 'bakery'];
      case MealType.lunch:
        return ['sandwich', 'american', 'italian'];
      case MealType.dinner:
        return ['american', 'italian', 'steakhouse'];
    }
  }

  List<int> _getPriceRangeForPreferences(List<FoodPreference> preferences) {
    if (preferences.contains(FoodPreference.fastService)) {
      return [1, 2];
    }
    return [1, 2, 3, 4];
  }

  bool _matchesPreferences(Place place, List<FoodPreference> preferences) {
    for (final pref in preferences) {
      switch (pref) {
        case FoodPreference.vegetarian:
        case FoodPreference.vegan:
        case FoodPreference.glutenFree:
          if (place.rating != null && place.rating! < 4.0) {
            return false;
          }
          break;
        case FoodPreference.kidFriendly:
        case FoodPreference.fastService:
        case FoodPreference.localCuisine:
        case FoodPreference.petFriendly:
        case FoodPreference.halal:
        case FoodPreference.kosher:
          break;
      }
    }
    return true;
  }

  List<FoodPreference> _getMatchingPreferences(
    Place place,
    List<FoodPreference> preferences,
  ) {
    return preferences.where((pref) {
      switch (pref) {
        case FoodPreference.localCuisine:
          return place.rating != null && place.rating! >= 4.5;
        case FoodPreference.fastService:
          return !(place.cuisineTypes?.contains('fine dining') ?? false);
        default:
          return true;
      }
    }).toList();
  }

  Future<Duration> _calculateDetour(
    LatLng currentLocation,
    LatLng stopLocation,
  ) async {
    final directDistance = _calculateDistance(currentLocation, stopLocation);
    return Duration(minutes: (directDistance / 0.5).round());
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 3958.8;

    final lat1Rad = start.latitude * (pi / 180);
    final lat2Rad = end.latitude * (pi / 180);
    final deltaLatRad = (end.latitude - start.latitude) * (pi / 180);
    final deltaLngRad = (end.longitude - start.longitude) * (pi / 180);

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
