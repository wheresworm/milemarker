// lib/core/models/place.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceType {
  restaurant,
  gas_station,
  convenience_store,
  lodging,
  tourist_attraction,
  other,
}

enum PriceLevel {
  free,
  inexpensive,
  moderate,
  expensive,
  veryExpensive,
}

class OpeningHours {
  final bool openNow;
  final List<Period> periods;
  final List<String> weekdayText;

  OpeningHours({
    required this.openNow,
    required this.periods,
    required this.weekdayText,
  });
}

class Period {
  final TimeOfDay? close;
  final TimeOfDay? open;
  final int day;

  Period({
    this.close,
    this.open,
    required this.day,
  });
}

class Place {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final List<String>? photoReferences;
  final PlaceType? type;
  final int? userRatingsTotal;
  final PriceLevel? priceLevel;
  final List<String>? photos;
  final OpeningHours? openingHours;
  final List<String>? amenities;

  Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    this.phoneNumber,
    this.website,
    this.rating,
    this.photoReferences,
    this.type,
    this.userRatingsTotal,
    this.priceLevel,
    this.photos,
    this.openingHours,
    this.amenities,
  });

  // Convenience getters
  String get id => placeId;

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'phoneNumber': phoneNumber,
      'website': website,
      'rating': rating,
      'photoReferences': photoReferences,
      'type': type?.toString(),
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel?.index,
      'photos': photos,
      'amenities': amenities,
    };
  }
}
