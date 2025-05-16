import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/stop.dart'; // Add this import for MealType
import '../../core/models/time_window.dart';
import '../../core/services/food_stop_service.dart';

class MealStopController extends ChangeNotifier {
  final FoodStopService foodStopService;

  MealStopController({required this.foodStopService});

  List<FoodSuggestion> _suggestions = [];
  List<FoodSuggestion> get suggestions => _suggestions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FoodStop? _selectedMealStop;
  FoodStop? get selectedMealStop => _selectedMealStop;

  // Get suggestions for a meal stop
  Future<List<FoodSuggestion>> getSuggestionsForMealStop(
      FoodStop mealStop) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use the existing findMealOptions method from your service
      _suggestions = await foodStopService.findMealOptions(
        mealType: mealStop.mealType,
        location: mealStop.location,
        targetTime: mealStop.timeWindow?.preferred ?? DateTime.now(),
        preferences: mealStop.preferences,
        maxDetour: mealStop.maxDetour,
      );
      _selectedMealStop = mealStop;
      return _suggestions;
    } catch (e) {
      debugPrint('Error getting food suggestions: $e');
      _suggestions = [];
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new meal stop with defaults
  FoodStop createDefaultMealStop({
    required String name,
    required LatLng location,
    required int order,
    required MealType mealType,
  }) {
    // Create a default meal stop with reasonable defaults
    final now = DateTime.now();

    const defaultDuration = Duration(minutes: 45); // Default meal duration
    final defaultPreferences = <FoodPreference>[]; // No preferences by default
    const defaultMaxDetour = Duration(minutes: 15); // 15 minutes max detour

    // Default time window (meal time ± 1 hour)
    final defaultTimeWindow = TimeWindow(
      earliest: now.subtract(const Duration(hours: 1)),
      latest: now.add(const Duration(hours: 1)),
      preferred: now,
    );

    final mealStop = FoodStop(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // Generate unique ID
      name: name,
      location: location,
      order: order,
      mealType: mealType,
      preferences: defaultPreferences,
      maxDetour: defaultMaxDetour,
      estimatedDuration: defaultDuration,
      timeWindow: defaultTimeWindow,
      notes: '',
    );

    return mealStop;
  }

  // Update an existing meal stop
  Future<void> updateMealStop(FoodStop updatedStop) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Here you would typically save this to your database via foodStopService
      // For now, we'll just update the local state
      _selectedMealStop = updatedStop;
    } catch (e) {
      debugPrint('Error updating meal stop: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current selection
  void clearSelection() {
    _selectedMealStop = null;
    _suggestions = [];
    notifyListeners();
  }
}
