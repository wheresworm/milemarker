// lib/core/services/places_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  late final String _apiKey;

  PlacesService() {
    _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  }

  // Method that food_stop_service expects
  Future<List<Place>> searchNearbyPlaces({
    required LatLng location,
    required int radius,
    PlaceType? type,
    String? keyword,
  }) async {
    final url = '$_baseUrl/nearbysearch/json?'
        'location=${location.latitude},${location.longitude}'
        '&radius=$radius'
        '${type != null ? '&type=${_getPlaceTypeString(type)}' : ''}'
        '${keyword != null ? '&keyword=$keyword' : ''}'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((placeJson) => _parsePlaceFromJson(placeJson))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Method expected by other parts of the app
  Future<List<Place>> searchNearby({
    required LatLng location,
    required double radius,
    required List<PlaceType> types,
    List<String>? cuisineTypes,
    List<int>? priceRange,
    double? minRating,
  }) async {
    // Convert to the simpler method
    final places = <Place>[];

    for (final type in types) {
      final results = await searchNearbyPlaces(
        location: location,
        radius: radius.toInt(),
        type: type,
      );

      // Filter by additional criteria
      final filtered = results.where((place) {
        if (minRating != null && (place.rating ?? 0) < minRating) {
          return false;
        }
        // Add more filters as needed
        return true;
      }).toList();

      places.addAll(filtered);
    }

    return places;
  }

  String _getPlaceTypeString(PlaceType type) {
    switch (type) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.gasStation:
        return 'gas_station';
      case PlaceType.hotel:
        return 'lodging';
      case PlaceType.convenienceStore:
        return 'convenience_store';
      case PlaceType.touristAttraction:
        return 'tourist_attraction';
      default:
        return 'point_of_interest';
    }
  }

  Place _parsePlaceFromJson(Map<String, dynamic> json) {
    return Place(
      id: json['place_id'],
      placeId: json['place_id'],
      name: json['name'],
      location: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
      address: json['vicinity'],
      type: _parsePlaceType(json['types']),
      rating: json['rating']?.toDouble(),
      reviewCount: json['user_ratings_total'],
      priceLevel: json['price_level'] != null
          ? PriceLevel.values[json['price_level']]
          : null,
    );
  }

  PlaceType _parsePlaceType(List<dynamic> types) {
    if (types.contains('restaurant')) return PlaceType.restaurant;
    if (types.contains('gas_station')) return PlaceType.gasStation;
    if (types.contains('lodging')) return PlaceType.hotel;
    if (types.contains('convenience_store')) return PlaceType.convenienceStore;
    if (types.contains('tourist_attraction'))
      return PlaceType.touristAttraction;
    return PlaceType.other;
  }

  // Add the missing searchPlaces method expected by PlacesController
  Future<List<Place>> searchPlaces(String query) async {
    final url = '$_baseUrl/textsearch/json?'
        'query=$query'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((placeJson) => _parsePlaceFromJson(placeJson))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
}
