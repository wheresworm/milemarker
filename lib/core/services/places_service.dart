import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/logger.dart';

class PlacesService {
  final String apiKey;
  final http.Client client;

  PlacesService({String? apiKey, http.Client? client})
    : apiKey = apiKey ?? dotenv.env['GOOGLE_API_KEY'] ?? '',
      client = client ?? http.Client();

  // Get suggestions for a location search
  Future<List<Map<String, dynamic>>> getPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$apiKey'
      '&components=country:us',
    );

    AppLogger.info('PlacesService: Fetching suggestions for: $input');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          AppLogger.info(
            'PlacesService: Found ${result['predictions'].length} suggestions',
          );
          return List<Map<String, dynamic>>.from(result['predictions']);
        } else {
          AppLogger.warning(
            'PlacesService: API returned status: ${result['status']}',
          );
          if (result.containsKey('error_message')) {
            AppLogger.warning('PlacesService: ${result['error_message']}');
          }
        }
      } else {
        AppLogger.severe('PlacesService: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.severe('PlacesService: Error fetching suggestions: $e');
    }

    return [];
  }

  // Get details of a place
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$apiKey'
      '&fields=geometry,formatted_address,name',
    );

    AppLogger.info('PlacesService: Fetching details for place: $placeId');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          AppLogger.info('PlacesService: Successfully fetched place details');
          return result['result'];
        } else {
          AppLogger.warning(
            'PlacesService: API returned status: ${result['status']}',
          );
          if (result.containsKey('error_message')) {
            AppLogger.warning('PlacesService: ${result['error_message']}');
          }
        }
      } else {
        AppLogger.severe('PlacesService: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.severe('PlacesService: Error fetching place details: $e');
    }

    return null;
  }

  // Search for nearby places
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required LatLng location,
    required String type,
    int radius = 5000,
    String? keyword,
  }) async {
    final keywordParam = keyword != null ? '&keyword=$keyword' : '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=$radius'
      '&type=$type'
      '$keywordParam'
      '&key=$apiKey',
    );

    AppLogger.info('PlacesService: Searching nearby places of type: $type');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          AppLogger.info(
            'PlacesService: Found ${result['results'].length} nearby places',
          );
          return List<Map<String, dynamic>>.from(result['results']);
        } else {
          AppLogger.warning(
            'PlacesService: API returned status: ${result['status']}',
          );
          if (result.containsKey('error_message')) {
            AppLogger.warning('PlacesService: ${result['error_message']}');
          }
        }
      } else {
        AppLogger.severe('PlacesService: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.severe('PlacesService: Error searching nearby places: $e');
    }

    return [];
  }
}
