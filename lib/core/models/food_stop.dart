// lib/core/models/food_stop.dart
import 'package:milemarker/core/models/stop.dart';
import 'package:milemarker/core/models/time_window.dart';
import 'package:milemarker/core/models/place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum FoodPreference {
  vegetarian,
  vegan,
  glutenFree,
  halal,
  kosher,
  kidFriendly,
  petFriendly,
  fastService,
  localCuisine,
}

class FoodSuggestion {
  final Place place;
  final double detourMinutes;
  final double detourMiles;
  final List<FoodPreference> matchingPreferences;

  FoodSuggestion({
    required this.place,
    required this.detourMinutes,
    required this.detourMiles,
    this.matchingPreferences = const [],
  });
}

class FoodStop extends Stop {
  final MealType mealType;
  final List<FoodPreference> preferences;
  final Duration maxDetour;
  final Place? selectedRestaurant;

  FoodStop({
    required String id,
    required String name,
    required LatLng location,
    required int order,
    required this.mealType, // Fixed: Remove the invalid "MealType" type declaration
    this.preferences = const [],
    this.maxDetour = const Duration(minutes: 15),
    this.selectedRestaurant,
    Duration estimatedDuration = const Duration(minutes: 45),
    TimeWindow? timeWindow,
    String? notes,
  }) : super(
          id: id,
          name: name,
          location: location,
          order: order,
          estimatedDuration: estimatedDuration,
          timeWindow: timeWindow,
          notes: notes,
        );

  @override
  StopType get stopType => StopType.food;

  @override
  String get categoryIcon {
    switch (mealType) {
      case MealType.breakfast:
        return 'restaurant';
      case MealType.lunch:
        return 'restaurant';
      case MealType.dinner:
        return 'restaurant';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'mealType': mealType.toString().split('.').last,
      'preferences':
          preferences.map((p) => p.toString().split('.').last).toList(),
      'maxDetour': maxDetour.inSeconds,
      'selectedRestaurant': selectedRestaurant?.toJson(),
    };
  }

  factory FoodStop.fromJson(Map<String, dynamic> json) {
    return FoodStop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      order: json['order'] as int,
      mealType: MealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['mealType'],
      ),
      preferences: (json['preferences'] as List<dynamic>?)
              ?.map((p) => FoodPreference.values.firstWhere(
                    (e) => e.toString().split('.').last == p,
                  ))
              .toList() ??
          [],
      maxDetour: Duration(seconds: json['maxDetour'] as int? ?? 900),
      selectedRestaurant: json['selectedRestaurant'] != null
          ? Place.fromJson(json['selectedRestaurant'] as Map<String, dynamic>)
          : null,
      estimatedDuration: Duration(
        minutes: json['estimatedDuration'] as int? ?? 45,
      ),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
