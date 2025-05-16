// lib/core/utils/polyline_utils.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineUtils {
  static String encode(List<LatLng> path) {
    List<int> result = [];
    int previousLatitude = 0;
    int previousLongitude = 0;

    for (LatLng point in path) {
      int latitude = (point.latitude * 1e5).round();
      int longitude = (point.longitude * 1e5).round();

      int deltaLatitude = latitude - previousLatitude;
      int deltaLongitude = longitude - previousLongitude;

      result.addAll(_encodeValue(deltaLatitude));
      result.addAll(_encodeValue(deltaLongitude));

      previousLatitude = latitude;
      previousLongitude = longitude;
    }

    return String.fromCharCodes(result);
  }

  static List<int> _encodeValue(int value) {
    value = value < 0 ? ~(value << 1) : value << 1;
    List<int> encoded = [];

    while (value >= 0x20) {
      encoded.add((value & 0x1f) | 0x20 + 63);
      value >>= 5;
    }

    encoded.add(value + 63);
    return encoded;
  }
}
