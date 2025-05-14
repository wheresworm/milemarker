// lib/core/models/place.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final List<String>? photoReferences;

  Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    this.phoneNumber,
    this.website,
    this.rating,
    this.photoReferences,
  });
}
