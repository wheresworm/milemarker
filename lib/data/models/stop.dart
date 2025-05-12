import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

enum StopType { breakfast, lunch, dinner, custom }

class Stop {
  // Unique identifier for the stop
  final String id;

  // Basic properties
  final String label;
  final StopType type;
  final DateTime plannedTime;
  final Duration dwellTime;

  // Location information
  final LatLng? location;
  final String? placeName;
  final String? placeAddress;

  // Create a new stop
  Stop({
    String? id,
    required this.label,
    required this.type,
    required this.plannedTime,
    required this.dwellTime,
    this.location,
    this.placeName,
    this.placeAddress,
  }) : id = id ?? const Uuid().v4();

  // Create a copy with some properties changed
  Stop copyWith({
    String? label,
    StopType? type,
    DateTime? plannedTime,
    Duration? dwellTime,
    LatLng? location,
    String? placeName,
    String? placeAddress,
  }) {
    return Stop(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      plannedTime: plannedTime ?? this.plannedTime,
      dwellTime: dwellTime ?? this.dwellTime,
      location: location ?? this.location,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
    );
  }

  // Convert to Map (useful for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.toString(),
      'plannedTime': plannedTime.millisecondsSinceEpoch,
      'dwellTimeInMinutes': dwellTime.inMinutes,
      'location':
          location != null
              ? {
                'latitude': location!.latitude,
                'longitude': location!.longitude,
              }
              : null,
      'placeName': placeName,
      'placeAddress': placeAddress,
    };
  }

  // Create from Map (useful for JSON deserialization)
  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      id: map['id'],
      label: map['label'],
      type: StopType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => StopType.custom,
      ),
      plannedTime: DateTime.fromMillisecondsSinceEpoch(map['plannedTime']),
      dwellTime: Duration(minutes: map['dwellTimeInMinutes']),
      location:
          map['location'] != null
              ? LatLng(
                map['location']['latitude'],
                map['location']['longitude'],
              )
              : null,
      placeName: map['placeName'],
      placeAddress: map['placeAddress'],
    );
  }

  // Helper to create meal stops
  static Stop createMealStop({
    required StopType mealType,
    required DateTime departureTime,
    Duration? offset,
  }) {
    String label;
    Duration defaultDwell = Duration(minutes: 30);
    Duration defaultOffset;

    switch (mealType) {
      case StopType.breakfast:
        label = 'Breakfast';
        defaultOffset = Duration(hours: 3);
        break;
      case StopType.lunch:
        label = 'Lunch';
        defaultOffset = Duration(hours: 6);
        break;
      case StopType.dinner:
        label = 'Dinner';
        defaultOffset = Duration(hours: 12);
        break;
      default:
        label = 'Meal Stop';
        defaultOffset = Duration(hours: 4);
    }

    return Stop(
      label: label,
      type: mealType,
      plannedTime: departureTime.add(offset ?? defaultOffset),
      dwellTime: defaultDwell,
    );
  }

  // Helper to create custom stop
  static Stop createCustomStop({
    required String label,
    required DateTime departureTime,
    Duration? offset,
    Duration? dwellTime,
  }) {
    return Stop(
      label: label,
      type: StopType.custom,
      plannedTime: departureTime.add(offset ?? Duration(hours: 2)),
      dwellTime: dwellTime ?? Duration(minutes: 15),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Stop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
