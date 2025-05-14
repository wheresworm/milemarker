import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../models/time_window.dart';

class PlacesService {
  final String? _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
  final http.Client _httpClient = http.Client();
  Timer? _debounceTimer;

  Future<List<Place>> searchPlaces({
    required String query,
    LatLng? location,
    double radiusMeters = 50000,
    PlaceType? type,
  }) async {
    if (_apiKey == null) {
      throw Exception('Google Places API key not found');
    }

    _debounceTimer?.cancel();
    final completer = Completer<List<Place>>();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final typeString = _getPlaceTypeString(type);
        final locationParam = location != null
            ? '&location=${location.latitude},${location.longitude}'
            : '';
        final typeParam = typeString != null ? '&type=$typeString' : '';

        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '$locationParam'
          '&radius=$radiusMeters'
          '$typeParam'
          '&key=$_apiKey',
        );

        final response = await _httpClient.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;
          final places =
              results.map((result) => _parsePlaceFromSearch(result)).toList();
          completer.complete(places);
        } else {
          completer.completeError(
            Exception('Failed to search places: ${response.statusCode}'),
          );
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  Future<List<Place>> searchAlongRoute({
    required List<LatLng> routePoints,
    required PlaceType type,
    double maxDetourMeters = 5000,
  }) async {
    if (_apiKey == null) {
      throw Exception('Google Places API key not found');
    }

    final places = <Place>[];

    // Sample route points to reduce API calls
    final sampleSize = routePoints.length > 20 ? 20 : routePoints.length;
    final step = routePoints.length ~/ sampleSize;

    for (int i = 0; i < routePoints.length; i += step) {
      final point = routePoints[i];
      final typeString = _getPlaceTypeString(type);

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${point.latitude},${point.longitude}'
        '&radius=$maxDetourMeters'
        '&type=$typeString'
        '&key=$_apiKey',
      );

      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        for (final result in results) {
          final place = _parsePlaceFromSearch(result);

          // Calculate actual detour distance (simplified)
          final detour = _calculateDetour(
            routePoints: routePoints,
            placeLocation: place.location,
          );

          if (detour <= maxDetourMeters &&
              !places.any((p) => p.placeId == place.placeId)) {
            places.add(place.copyWith(distanceFromRoute: detour));
          }
        }
      }
    }

    return places;
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    if (_apiKey == null) {
      throw Exception('Google Places API key not found');
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=place_id,name,geometry,formatted_address,types,rating,'
      'user_ratings_total,price_level,opening_hours,photos,formatted_phone_number,website'
      '&key=$_apiKey',
    );

    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];
      return _parsePlaceFromDetails(result);
    } else {
      throw Exception('Failed to get place details: ${response.statusCode}');
    }
  }

  Place _parsePlaceFromSearch(Map<String, dynamic> result) {
    final location = result['geometry']['location'];
    final types = List<String>.from(result['types'] ?? []);

    return Place(
      id: result['place_id'],
      placeId: result['place_id'],
      name: result['name'],
      location: LatLng(location['lat'], location['lng']),
      address: result['formatted_address'] ?? result['vicinity'],
      type: _getPlaceTypeFromTypes(types),
      rating: result['rating']?.toDouble(),
      reviewCount: result['user_ratings_total'],
      priceLevel: _parsePriceLevel(result['price_level']),
      openingHours: _parseOpeningHours(result['opening_hours']),
      photoUrl: _getPhotoUrl(result['photos']),
    );
  }

  Place _parsePlaceFromDetails(Map<String, dynamic> result) {
    final location = result['geometry']['location'];
    final types = List<String>.from(result['types'] ?? []);

    return Place(
      id: result['place_id'],
      placeId: result['place_id'],
      name: result['name'],
      location: LatLng(location['lat'], location['lng']),
      address: result['formatted_address'],
      type: _getPlaceTypeFromTypes(types),
      rating: result['rating']?.toDouble(),
      reviewCount: result['user_ratings_total'],
      priceLevel: _parsePriceLevel(result['price_level']),
      openingHours: _parseOpeningHours(result['opening_hours']),
      photoUrl: _getPhotoUrl(result['photos']),
      phoneNumber: result['formatted_phone_number'],
      website: result['website'],
    );
  }

  OpeningHours? _parseOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return null;

    final periods = <OpeningPeriod>[];
    final periodsList = openingHours['periods'] as List?;

    if (periodsList != null) {
      for (final period in periodsList) {
        final open = period['open'];
        final close = period['close'];

        if (open != null && close != null) {
          periods.add(OpeningPeriod(
            day: open['day'],
            open: _parseTime(open['time']),
            close: _parseTime(close['time']),
          ));
        }
      }
    }

    return OpeningHours(
      openNow: openingHours['open_now'] ?? false,
      periods: periods,
    );
  }

  TimeOfDay _parseTime(String time) {
    final hour = int.parse(time.substring(0, 2));
    final minute = int.parse(time.substring(2, 4));
    return TimeOfDay(hour: hour, minute: minute);
  }

  PlaceType _getPlaceTypeFromTypes(List<String> types) {
    if (types.contains('restaurant') || types.contains('food')) {
      return PlaceType.restaurant;
    } else if (types.contains('gas_station')) {
      return PlaceType.gasStation;
    } else if (types.contains('convenience_store')) {
      return PlaceType.convenienceStore;
    } else if (types.contains('lodging')) {
      return PlaceType.hotel;
    } else if (types.contains('tourist_attraction')) {
      return PlaceType.touristAttraction;
    }
    return PlaceType.other;
  }

  String? _getPlaceTypeString(PlaceType? type) {
    if (type == null) return null;

    switch (type) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.gasStation:
        return 'gas_station';
      case PlaceType.convenienceStore:
        return 'convenience_store';
      case PlaceType.hotel:
        return 'lodging';
      case PlaceType.restArea:
        return 'rest_stop';
      case PlaceType.touristAttraction:
        return 'tourist_attraction';
      case PlaceType.attraction:
        return 'tourist_attraction';
      case PlaceType.other:
        return null;
    }
  }

  PriceLevel? _parsePriceLevel(int? level) {
    if (level == null) return null;

    switch (level) {
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

  String? _getPhotoUrl(List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) return null;

    final photo = photos.first;
    final photoReference = photo['photo_reference'];

    if (photoReference == null) return null;

    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  double _calculateDetour({
    required List<LatLng> routePoints,
    required LatLng placeLocation,
  }) {
    // Simple approximation - find nearest point on route
    double minDistance = double.infinity;

    for (final point in routePoints) {
      final distance = _calculateDistance(point, placeLocation);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = p1.latitude * (3.141592653589793 / 180);
    final double lat2Rad = p2.latitude * (3.141592653589793 / 180);
    final double deltaLat =
        (p2.latitude - p1.latitude) * (3.141592653589793 / 180);
    final double deltaLng =
        (p2.longitude - p1.longitude) * (3.141592653589793 / 180);

    final double a = (deltaLat / 2).sin() * (deltaLat / 2).sin() +
        lat1Rad.cos() *
            lat2Rad.cos() *
            (deltaLng / 2).sin() *
            (deltaLng / 2).sin();

    final double c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _httpClient.close();
  }
}
