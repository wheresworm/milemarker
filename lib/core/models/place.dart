import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceType {
  restaurant,
  gasStation,
  hotel,
  attraction,
  restArea,
  other,
}

class Place {
  final String id;
  final String name;
  final LatLng location;
  final String address;
  final PlaceType type;
  final double? rating;
  final int? userRatingsTotal;
  final PriceLevel? priceLevel;
  final List<String> photos;
  final OpeningHours? openingHours;
  final String? phoneNumber;
  final String? website;
  final List<String> amenities;

  Place({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.type,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.photos = const [],
    this.openingHours,
    this.phoneNumber,
    this.website,
    this.amenities = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
        'address': address,
        'type': type.toString(),
        'rating': rating,
        'userRatingsTotal': userRatingsTotal,
        'priceLevel': priceLevel?.toString(),
        'photos': photos,
        'openingHours': openingHours?.toMap(),
        'phoneNumber': phoneNumber,
        'website': website,
        'amenities': amenities,
      };

  factory Place.fromMap(Map<String, dynamic> map) => Place(
        id: map['id'],
        name: map['name'],
        location: LatLng(
          map['location']['lat'],
          map['location']['lng'],
        ),
        address: map['address'],
        type: PlaceType.values.firstWhere(
          (e) => e.toString() == map['type'],
          orElse: () => PlaceType.other,
        ),
        rating: map['rating']?.toDouble(),
        userRatingsTotal: map['userRatingsTotal'],
        priceLevel: map['priceLevel'] != null
            ? PriceLevel.values
                .firstWhere((e) => e.toString() == map['priceLevel'])
            : null,
        photos: List<String>.from(map['photos'] ?? []),
        openingHours: map['openingHours'] != null
            ? OpeningHours.fromMap(map['openingHours'])
            : null,
        phoneNumber: map['phoneNumber'],
        website: map['website'],
        amenities: List<String>.from(map['amenities'] ?? []),
      );
}

class OpeningHours {
  final bool isOpenNow;
  final List<String> weekdayText;
  final List<Period> periods;

  OpeningHours({
    required this.isOpenNow,
    required this.weekdayText,
    required this.periods,
  });

  bool isOpenAt(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday;
    final timeOfDay = dateTime.hour * 60 + dateTime.minute;

    return periods.any((period) =>
        period.dayOfWeek == dayOfWeek &&
        period.openTime <= timeOfDay &&
        period.closeTime > timeOfDay);
  }

  Map<String, dynamic> toMap() => {
        'isOpenNow': isOpenNow,
        'weekdayText': weekdayText,
        'periods': periods.map((p) => p.toMap()).toList(),
      };

  factory OpeningHours.fromMap(Map<String, dynamic> map) => OpeningHours(
        isOpenNow: map['isOpenNow'],
        weekdayText: List<String>.from(map['weekdayText']),
        periods:
            (map['periods'] as List).map((p) => Period.fromMap(p)).toList(),
      );
}

class Period {
  final int dayOfWeek; // 1-7, Monday is 1
  final int openTime; // Minutes from midnight
  final int closeTime; // Minutes from midnight

  Period({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'openTime': openTime,
        'closeTime': closeTime,
      };

  factory Period.fromMap(Map<String, dynamic> map) => Period(
        dayOfWeek: map['dayOfWeek'],
        openTime: map['openTime'],
        closeTime: map['closeTime'],
      );
}

enum PriceLevel { free, cheap, moderate, expensive, veryExpensive }
