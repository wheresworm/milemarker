import 'place.dart';

class MealPreferences {
  final List<String>? cuisineTypes;
  final PriceLevel? maxPriceLevel;
  final double? maxDetourDistance; // meters
  final bool preferChainRestaurants;
  final bool avoidFastFood;
  final double minRating;
  final List<String>? dietaryRestrictions;
  final List<String>? preferredChains;
  final List<String>? avoidChains;

  MealPreferences({
    this.cuisineTypes,
    this.maxPriceLevel,
    this.maxDetourDistance,
    this.preferChainRestaurants = false,
    this.avoidFastFood = false,
    this.minRating = 3.5,
    this.dietaryRestrictions,
    this.preferredChains,
    this.avoidChains,
  });

  MealPreferences copyWith({
    List<String>? cuisineTypes,
    PriceLevel? maxPriceLevel,
    double? maxDetourDistance,
    bool? preferChainRestaurants,
    bool? avoidFastFood,
    double? minRating,
    List<String>? dietaryRestrictions,
    List<String>? preferredChains,
    List<String>? avoidChains,
  }) {
    return MealPreferences(
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      maxPriceLevel: maxPriceLevel ?? this.maxPriceLevel,
      maxDetourDistance: maxDetourDistance ?? this.maxDetourDistance,
      preferChainRestaurants:
          preferChainRestaurants ?? this.preferChainRestaurants,
      avoidFastFood: avoidFastFood ?? this.avoidFastFood,
      minRating: minRating ?? this.minRating,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      preferredChains: preferredChains ?? this.preferredChains,
      avoidChains: avoidChains ?? this.avoidChains,
    );
  }

  Map<String, dynamic> toJson() => {
        'cuisineTypes': cuisineTypes,
        'maxPriceLevel': maxPriceLevel?.toString().split('.').last,
        'maxDetourDistance': maxDetourDistance,
        'preferChainRestaurants': preferChainRestaurants,
        'avoidFastFood': avoidFastFood,
        'minRating': minRating,
        'dietaryRestrictions': dietaryRestrictions,
        'preferredChains': preferredChains,
        'avoidChains': avoidChains,
      };

  factory MealPreferences.fromJson(Map<String, dynamic> json) {
    return MealPreferences(
      cuisineTypes: json['cuisineTypes'] != null
          ? List<String>.from(json['cuisineTypes'])
          : null,
      maxPriceLevel: json['maxPriceLevel'] != null
          ? PriceLevel.values.firstWhere(
              (p) => p.toString().split('.').last == json['maxPriceLevel'],
              orElse: () => PriceLevel.moderate,
            )
          : null,
      maxDetourDistance: json['maxDetourDistance']?.toDouble(),
      preferChainRestaurants: json['preferChainRestaurants'] ?? false,
      avoidFastFood: json['avoidFastFood'] ?? false,
      minRating: json['minRating']?.toDouble() ?? 3.5,
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? List<String>.from(json['dietaryRestrictions'])
          : null,
      preferredChains: json['preferredChains'] != null
          ? List<String>.from(json['preferredChains'])
          : null,
      avoidChains: json['avoidChains'] != null
          ? List<String>.from(json['avoidChains'])
          : null,
    );
  }
}
