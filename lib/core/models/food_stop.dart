import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';
import 'place.dart';

class FoodStop extends Stop {
  final MealType mealType;
  final List<FoodPreference> preferences;
  final Duration maxDetour;
  final Place? selectedRestaurant;
  final List<FoodSuggestion>? suggestions;

  FoodStop({
    required String id,
    required LatLng location,
    required String name,
    required int order,
    required this.mealType,
    required this.preferences,
    this.maxDetour = const Duration(minutes: 10),
    this.selectedRestaurant,
    this.suggestions,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
  }) : super(
          id: id,
          location: location,
          name: name,
          type: StopType.food,
          order: order,
          estimatedDuration: estimatedDuration ?? const Duration(minutes: 45),
          timeWindow: timeWindow,
          notes: notes,
        );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
        'name': name,
        'type': type.toString(),
        'order': order,
        'estimatedDuration': estimatedDuration?.inSeconds,
        'timeWindow': timeWindow?.toMap(),
        'notes': notes,
        'mealType': mealType.toString(),
        'preferences': preferences.map((p) => p.toMap()).toList(),
        'maxDetour': maxDetour.inSeconds,
        'selectedRestaurant': selectedRestaurant?.toMap(),
      };

  @override
  FoodStop copyWith({
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
    Place? selectedRestaurant,
    List<FoodSuggestion>? suggestions,
  }) =>
      FoodStop(
        id: id,
        location: selectedRestaurant?.location ?? location,
        name: selectedRestaurant?.name ?? name,
        order: order ?? this.order,
        mealType: mealType,
        preferences: preferences,
        maxDetour: maxDetour,
        selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
        suggestions: suggestions ?? this.suggestions,
        estimatedDuration: estimatedDuration ?? this.estimatedDuration,
        timeWindow: timeWindow ?? this.timeWindow,
        notes: notes ?? this.notes,
      );
}

class FoodPreference {
  final String? category; // fast-food, sit-down, coffee
  final List<String> chains; // ["McDonald's", "Chick-fil-A"]
  final List<String> cuisines; // ["Mexican", "Italian"]
  final PriceLevel? priceLevel;

  FoodPreference({
    this.category,
    this.chains = const [],
    this.cuisines = const [],
    this.priceLevel,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'chains': chains,
        'cuisines': cuisines,
        'priceLevel': priceLevel?.toString(),
      };

  factory FoodPreference.fromMap(Map<String, dynamic> map) => FoodPreference(
        category: map['category'],
        chains: List<String>.from(map['chains'] ?? []),
        cuisines: List<String>.from(map['cuisines'] ?? []),
        priceLevel: map['priceLevel'] != null
            ? PriceLevel.values
                .firstWhere((e) => e.toString() == map['priceLevel'])
            : null,
      );
}

class FoodSuggestion {
  final Place restaurant;
  final Duration detour;
  final double rating;
  final bool currentlyOpen;
  final PriceLevel priceLevel;
  final List<String> popularItems;
  final double distance; // miles

  FoodSuggestion({
    required this.restaurant,
    required this.detour,
    required this.rating,
    required this.currentlyOpen,
    required this.priceLevel,
    required this.popularItems,
    required this.distance,
  });
}

enum PriceLevel { free, cheap, moderate, expensive, veryExpensive }
