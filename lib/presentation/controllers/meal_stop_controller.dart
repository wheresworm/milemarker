import 'package:flutter/material.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/meal_preferences.dart';
import '../../core/models/user_route.dart';
import '../../core/services/food_stop_service.dart';

class MealStopController extends ChangeNotifier {
  final FoodStopService _foodStopService;

  List<FoodStop> _suggestedStops = [];
  MealPreferences _preferences = MealPreferences();
  bool _isLoading = false;
  String? _error;

  List<FoodStop> get suggestedStops => _suggestedStops;
  MealPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MealStopController({required FoodStopService foodStopService})
      : _foodStopService = foodStopService;

  Future<void> suggestMealStops(UserRoute route) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suggestedStops = await _foodStopService.suggestMealStops(
        route: route,
        preferences: _preferences,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void updatePreferences(MealPreferences preferences) {
    _preferences = preferences;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestedStops.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
