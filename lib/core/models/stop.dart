// lib/core/models/stop.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'time_window.dart';

class Stop {
  final String id;
  final String name;
  final LatLng location;
  final int order;
  final Duration estimatedDuration;
  final TimeWindow? timeWindow;
  final String? notes;

  Stop({
    required this.id,
    required this.name,
    required this.location,
    required this.order,
    this.estimatedDuration = const Duration(minutes: 30),
    this.timeWindow,
    this.notes,
  });

  StopType get stopType => StopType.custom; // Default implementation

  String get categoryIcon {
    switch (stopType) {
      case StopType.food:
        return 'restaurant';
      case StopType.fuel:
        return 'local_gas_station';
      case StopType.hotel:
        return 'hotel';
      case StopType.rest:
        return 'local_parking';
      case StopType.scenic:
        return 'landscape';
      case StopType.place:
        return 'place';
      default:
        return 'location_on';
    }
  }

  Stop copyWith({
    String? id,
    String? name,
    LatLng? location,
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      order: order ?? this.order,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      timeWindow: timeWindow ?? this.timeWindow,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'order': order,
        'estimatedDuration': estimatedDuration.inMinutes,
        'timeWindow': timeWindow?.toJson(),
        'notes': notes,
        'type': stopType.toString().split('.').last,
      };

  Map<String, dynamic> toMap() => toJson();

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      order: json['order'],
      estimatedDuration: Duration(minutes: json['estimatedDuration'] ?? 30),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      notes: json['notes'],
    );
  }
}

enum StopType {
  origin,
  destination,
  food,
  fuel,
  rest,
  hotel,
  scenic,
  place,
  custom
}

enum MealType { breakfast, lunch, dinner }
