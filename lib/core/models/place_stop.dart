// lib/core/models/meal_preferences.dart
import 'food_stop.dart';

class MealPreferences {
  final List<FoodPreference> preferences;
  final Duration maxDetour;
  final double minRating;

  MealPreferences({
    this.preferences = const [],
    this.maxDetour = const Duration(minutes: 15),
    this.minRating = 3.5,
  });

  // Convert to list for compatibility
  List<FoodPreference> toList() => preferences;
}
