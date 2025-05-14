import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';
import '../config/api_config.dart';

class PlacesService {
  static const String _placesUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey = ApiConfig.googleApiKey;

  PlacesService();

  // Search for places by text query
  Future<List<Place>> searchPlaces({
    required String query,
    LatLng? location,
    int radius = 50000, // 50km default
  }) async {
    final uri = Uri.parse('$_placesUrl/textsearch/json').replace(
      queryParameters: {
        'query': query,
        if (location != null)
          'location': '${location.latitude},${location.longitude}',
        if (location != null) 'radius': radius.toString(),
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search places: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Places API error: ${json['status']}');
    }

    return (json['results'] as List)
        .map((place) => _placeFromJson(place))
        .toList();
  }

  // Search nearby places
  Future<List<Place>> searchNearby({
    required LatLng location,
    required int radius,
    List<PlaceType>? types,
    String? keyword,
  }) async {
    final uri = Uri.parse('$_placesUrl/nearbysearch/json').replace(
      queryParameters: {
        'location': '${location.latitude},${location.longitude}',
        'radius': radius.toString(),
        if (types != null) 'type': _typeToString(types.first),
        if (keyword != null) 'keyword': keyword,
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search nearby: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Places API error: ${json['status']}');
    }

    return (json['results'] as List)
        .map((place) => _placeFromJson(place))
        .toList();
  }

  // Get place details
  Future<Place> getPlaceDetails(String placeId) async {
    final uri = Uri.parse('$_placesUrl/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'place_id,name,geometry,formatted_address,types,rating,'
            'user_ratings_total,price_level,photos,opening_hours,'
            'formatted_phone_number,website',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get place details: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK') {
      throw Exception('Places API error: ${json['status']}');
    }

    return _placeFromJson(json['result'], detailed: true);
  }

  // Autocomplete place search
  Future<List<AutocompletePrediction>> autocomplete({
    required String input,
    LatLng? location,
    int radius = 50000,
  }) async {
    final uri = Uri.parse('$_placesUrl/autocomplete/json').replace(
      queryParameters: {
        'input': input,
        if (location != null)
          'location': '${location.latitude},${location.longitude}',
        if (location != null) 'radius': radius.toString(),
        'types': 'establishment',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to autocomplete: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
      throw Exception('Places API error: ${json['status']}');
    }

    return (json['predictions'] as List)
        .map((pred) => AutocompletePrediction.fromJson(pred))
        .toList();
  }

  Place _placeFromJson(Map<String, dynamic> json, {bool detailed = false}) {
    return Place(
      id: json['place_id'],
      name: json['name'],
      location: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      type: _typeFromJson(json['types'] ?? []),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: _priceLevelFromJson(json['price_level']),
      photos: (json['photos'] as List?)
              ?.map((photo) => photo['photo_reference'] as String)
              .toList() ??
          [],
      openingHours: detailed && json['opening_hours'] != null
          ? OpeningHours(
              isOpenNow: json['opening_hours']['open_now'] ?? false,
              weekdayText: List<String>.from(
                json['opening_hours']['weekday_text'] ?? [],
              ),
              periods: (json['opening_hours']['periods'] as List?)
                      ?.map((period) => Period(
                            dayOfWeek: period['open']['day'],
                            openTime: period['open']['time'] != null
                                ? int.parse(period['open']['time'])
                                : 0,
                            closeTime: period['close']?['time'] != null
                                ? int.parse(period['close']['time'])
                                : 2359,
                          ))
                      .toList() ??
                  [],
            )
          : null,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
    );
  }

  PlaceType _typeFromJson(List<dynamic> types) {
    if (types.contains('restaurant') || types.contains('food')) {
      return PlaceType.restaurant;
    } else if (types.contains('gas_station')) {
      return PlaceType.gasStation;
    } else if (types.contains('lodging')) {
      return PlaceType.hotel;
    } else if (types.contains('rest_stop')) {
      return PlaceType.restArea;
    } else if (types.contains('tourist_attraction')) {
      return PlaceType.attraction;
    }
    return PlaceType.other;
  }

  String _typeToString(PlaceType type) {
    switch (type) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.gasStation:
        return 'gas_station';
      case PlaceType.hotel:
        return 'lodging';
      case PlaceType.restArea:
        return 'rest_stop';
      case PlaceType.attraction:
        return 'tourist_attraction';
      default:
        return 'establishment';
    }
  }

  PriceLevel? _priceLevelFromJson(int? level) {
    switch (level) {
      case 0:
        return PriceLevel.free;
      case 1:
        return PriceLevel.cheap;
      case 2:
        return PriceLevel.moderate;
      case 3:
        return PriceLevel.expensive;
      case 4:
        return PriceLevel.veryExpensive;
      default:
        return null;
    }
  }
}

class AutocompletePrediction {
  final String description;
  final String placeId;
  final List<String> types;

  AutocompletePrediction({
    required this.description,
    required this.placeId,
    required this.types,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) =>
      AutocompletePrediction(
        description: json['description'],
        placeId: json['place_id'],
        types: List<String>.from(json['types'] ?? []),
      );
}
