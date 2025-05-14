import 'package:flutter/material.dart'; // Added for TimeOfDay
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'time_window.dart';

enum PlaceType {
  restaurant,
  gasStation, // Changed from gas_station to match enum naming convention
  convenienceStore, // Changed from convenience_store
  hotel,
  touristAttraction, // Changed from tourist_attraction
  restArea, // Added missing enum value
  attraction, // Added missing enum value
  other
}

enum PriceLevel { cheap, moderate, expensive, veryExpensive }

class Place {
  final String id;
  final String placeId; // Added placeId field
  final String name;
  final LatLng location;
  final String? address;
  final PlaceType type;
  final double? rating;
  final int? reviewCount;
  final PriceLevel? priceLevel;
  final double? distanceFromRoute;
  final List<String>? cuisineTypes;
  final OpeningHours? openingHours;
  final TimeWindow? timeWindow;
  final String? photoUrl;
  final String? phoneNumber;
  final String? website;

  Place({
    required this.id,
    required this.placeId,
    required this.name,
    required this.location,
    this.address,
    required this.type,
    this.rating,
    this.reviewCount,
    this.priceLevel,
    this.distanceFromRoute,
    this.cuisineTypes,
    this.openingHours,
    this.timeWindow,
    this.photoUrl,
    this.phoneNumber,
    this.website,
  });

  bool get isGasStation => type == PlaceType.gasStation;
  bool get isRestaurant => type == PlaceType.restaurant;

  Place copyWith({
    String? id,
    String? placeId,
    String? name,
    LatLng? location,
    String? address,
    PlaceType? type,
    double? rating,
    int? reviewCount,
    PriceLevel? priceLevel,
    double? distanceFromRoute,
    List<String>? cuisineTypes,
    OpeningHours? openingHours,
    TimeWindow? timeWindow,
    String? photoUrl,
    String? phoneNumber,
    String? website,
  }) {
    return Place(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      distanceFromRoute: distanceFromRoute ?? this.distanceFromRoute,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      openingHours: openingHours ?? this.openingHours,
      timeWindow: timeWindow ?? this.timeWindow,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': address,
        'type': type.toString().split('.').last,
        'rating': rating,
        'reviewCount': reviewCount,
        'priceLevel': priceLevel?.toString().split('.').last,
        'distanceFromRoute': distanceFromRoute,
        'cuisineTypes': cuisineTypes,
        'openingHours': openingHours?.toJson(),
        'timeWindow': timeWindow?.toJson(),
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'website': website,
      };

  Map<String, dynamic> toMap() => toJson(); // Alias for database compatibility

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      placeId: json['placeId'] ??
          json['id'], // Fallback to id if placeId not present
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      address: json['address'],
      type: PlaceType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => PlaceType.other,
      ),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      priceLevel: json['priceLevel'] != null
          ? PriceLevel.values.firstWhere(
              (p) => p.toString().split('.').last == json['priceLevel'],
              orElse: () => PriceLevel.moderate,
            )
          : null,
      distanceFromRoute: json['distanceFromRoute']?.toDouble(),
      cuisineTypes: json['cuisineTypes'] != null
          ? List<String>.from(json['cuisineTypes'])
          : null,
      openingHours: json['openingHours'] != null
          ? OpeningHours.fromJson(json['openingHours'])
          : null,
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      photoUrl: json['photoUrl'],
      phoneNumber: json['phoneNumber'],
      website: json['website'],
    );
  }
}

class OpeningHours {
  final bool openNow;
  final List<OpeningPeriod> periods;

  OpeningHours({
    required this.openNow,
    required this.periods,
  });

  bool isOpenAt(DateTime time) {
    if (periods.isEmpty) return openNow;

    final dayOfWeek = time.weekday % 7; // Convert to 0-6 (Sunday-Saturday)
    final timeOfDay = TimeOfDay.fromDateTime(time);

    for (final period in periods) {
      if (period.day == dayOfWeek) {
        if (period.isOpenAt(timeOfDay)) {
          return true;
        }
      }
    }

    return false;
  }

  Map<String, dynamic> toJson() => {
        'openNow': openNow,
        'periods': periods.map((p) => p.toJson()).toList(),
      };

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['openNow'] ?? false,
      periods: (json['periods'] as List?)
              ?.map((p) => OpeningPeriod.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class OpeningPeriod {
  final int day;
  final TimeOfDay open;
  final TimeOfDay close;

  OpeningPeriod({
    required this.day,
    required this.open,
    required this.close,
  });

  bool isOpenAt(TimeOfDay time) {
    // Handle overnight hours (e.g., 10 PM - 2 AM)
    if (close.hour < open.hour) {
      return time.hour >= open.hour ||
          time.hour < close.hour ||
          (time.hour == close.hour && time.minute < close.minute);
    }

    // Normal hours
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;
    final timeMinutes = time.hour * 60 + time.minute;

    return timeMinutes >= openMinutes && timeMinutes < closeMinutes;
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'open':
            '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}',
        'close':
            '${close.hour.toString().padLeft(2, '0')}:${close.minute.toString().padLeft(2, '0')}',
      };

  factory OpeningPeriod.fromJson(Map<String, dynamic> json) {
    final openParts = json['open'].split(':');
    final closeParts = json['close'].split(':');

    return OpeningPeriod(
      day: json['day'],
      open: TimeOfDay(
        hour: int.parse(openParts[0]),
        minute: int.parse(openParts[1]),
      ),
      close: TimeOfDay(
        hour: int.parse(closeParts[0]),
        minute: int.parse(closeParts[1]),
      ),
    );
  }
}
