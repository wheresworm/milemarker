import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/place.dart';
import '../../core/services/places_service.dart';

class PlacesController extends ChangeNotifier {
  final PlacesService _placesService;

  List<Place> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Place> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlacesController({required PlacesService placesService})
      : _placesService = placesService;

  Future<void> searchPlaces({
    required String query,
    LatLng? location,
    double radiusMeters = 50000,
    PlaceType? type,
  }) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _placesService.searchPlaces(
        query: query,
        location: location,
        radiusMeters: radiusMeters,
        type: type,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('Error searching places: $e');
      notifyListeners();
    }
  }

  Future<void> searchNearby({
    required LatLng location,
    required PlaceType type,
    double radiusMeters = 5000,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert type to search query
      String query = _getQueryForType(type);

      _searchResults = await _placesService.searchPlaces(
        query: query,
        location: location,
        radiusMeters: radiusMeters,
        type: type,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('Error searching nearby: $e');
      notifyListeners();
    }
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    try {
      return await _placesService.getPlaceDetails(placeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearResults() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getQueryForType(PlaceType type) {
    switch (type) {
      case PlaceType.restaurant:
        return 'restaurant';
      case PlaceType.gasStation:
        return 'gas station';
      case PlaceType.hotel:
        return 'hotel';
      case PlaceType.convenienceStore:
        return 'convenience store';
      case PlaceType.touristAttraction:
        return 'tourist attraction';
      default:
        return '';
    }
  }
}
