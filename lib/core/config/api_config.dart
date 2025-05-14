import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // Same key is usually used for both Maps and Places
  static String get googleApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}

// Validate that keys are loaded
class ApiKeyValidator {
  static bool validateKeys() {
    if (ApiConfig.googleApiKey.isEmpty) {
      throw Exception(
          'Google API key not found. Please add GOOGLE_MAPS_API_KEY to your .env file');
    }
    return true;
  }
}
