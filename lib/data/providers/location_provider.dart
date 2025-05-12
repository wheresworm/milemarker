import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/logger.dart';

class LocationProvider extends ChangeNotifier {
  // Cache for geocoding results to minimize API calls
  final Map<String, LatLng> _geocodeCache = {};

  // Getter for the cache
  Map<String, LatLng> get geocodeCache => _geocodeCache;

  // Method to geocode an address
  Future<LatLng?> geocodeAddress(String address) async {
    // Check cache first
    if (_geocodeCache.containsKey(address)) {
      AppLogger.info('LocationProvider: Using cached geocode for $address');
      return _geocodeCache[address];
    }

    AppLogger.info('LocationProvider: Geocoding address: $address');

    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        // Cache the result
        _geocodeCache[address] = latLng;

        AppLogger.info('LocationProvider: Successfully geocoded $address');
        return latLng;
      } else {
        AppLogger.warning('LocationProvider: No locations found for $address');
        return null;
      }
    } catch (e) {
      AppLogger.severe('LocationProvider: Error geocoding address: $e');
      return null;
    }
  }

  // Method to reverse geocode a LatLng
  Future<String?> reverseGeocode(LatLng latLng) async {
    AppLogger.info('LocationProvider: Reverse geocoding $latLng');

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';

        AppLogger.info(
          'LocationProvider: Successfully reverse geocoded $latLng',
        );
        return address;
      } else {
        AppLogger.warning('LocationProvider: No placemarks found for $latLng');
        return null;
      }
    } catch (e) {
      AppLogger.severe('LocationProvider: Error reverse geocoding: $e');
      return null;
    }
  }

  // Clear cache
  void clearCache() {
    _geocodeCache.clear();
    notifyListeners();
  }
}
