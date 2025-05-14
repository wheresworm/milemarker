import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place.dart';
import 'stop.dart';
import 'time_window.dart';

enum MealType { breakfast, lunch, dinner }

class FoodStop extends Stop {
  final MealType mealType;
  final String? cuisineType;
  final double? rating;
  final PriceLevel? priceLevel;
  final String? placeId;

  FoodStop({
    super.id,
    required super.name,
    required super.location,
    required super.order,
    super.estimatedDuration = const Duration(minutes: 45),
    super.timeWindow,
    super.notes,
    required this.mealType,
    this.cuisineType,
    this.rating,
    this.priceLevel,
    required this.placeId,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'mealType': mealType.toString().split('.').last,
      'cuisineType': cuisineType,
      'rating': rating,
      'priceLevel': priceLevel?.toString().split('.').last,
      'placeId': placeId,
    });
    return json;
  }

  factory FoodStop.fromJson(Map<String, dynamic> json) {
    return FoodStop(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      order: json['order'],
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'])
          : const Duration(minutes: 45),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      notes: json['notes'],
      mealType: MealType.values.firstWhere(
        (t) => t.toString().split('.').last == json['mealType'],
      ),
      cuisineType: json['cuisineType'],
      rating: json['rating']?.toDouble(),
      priceLevel: json['priceLevel'] != null
          ? PriceLevel.values.firstWhere(
              (p) => p.toString().split('.').last == json['priceLevel'],
            )
          : null,
      placeId: json['placeId'],
    );
  }
}
