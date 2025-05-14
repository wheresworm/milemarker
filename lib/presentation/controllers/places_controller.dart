// lib/presentation/controllers/places_controller.dart
import 'package:flutter/material.dart';
import '../../core/models/place.dart' as place_model;
import '../../core/services/places_service.dart';

class PlacesController extends ChangeNotifier {
  final PlacesService _placesService;
  List<place_model.Place> _searchResults = [];
  bool _isLoading = false;

  PlacesController(this._placesService);

  List<place_model.Place> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> searchPlaces({required String query}) async {
    if (query.isEmpty) {
      clearPlaces();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _placesService.searchPlaces(query: query);
    } catch (e) {
      print('Error searching places: $e');
      _searchResults = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearPlaces() {
    _searchResults = [];
    notifyListeners();
  }
}
