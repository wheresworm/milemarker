// lib/presentation/controllers/places_controller.dart
import 'package:flutter/foundation.dart';
import '../../core/models/place.dart';
import '../../core/services/places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesController extends ChangeNotifier {
  final PlacesService _placesService;

  List<Place> _places = [];
  List<Place> get places => _places;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PlacesController({PlacesService? placesService})
      : _placesService = placesService ?? PlacesService();

  Future<void> searchPlaces(
    String query, {
    LatLng? location,
    double? radiusMeters,
    PlaceType? type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (location != null) {
        _places = await _placesService.searchNearbyPlaces(
          location: location,
          radius: radiusMeters?.toInt() ?? 5000,
          type: type,
          keyword: query,
        );
      } else {
        _places = await _placesService.searchPlaces(query);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Error searching places: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    try {
      // Implementation needed in PlacesService
      final places = await _placesService.searchPlaces(placeId);
      return places.isNotEmpty ? places.first : null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  void clearPlaces() {
    _places = [];
    _errorMessage = null;
    notifyListeners();
  }
}
