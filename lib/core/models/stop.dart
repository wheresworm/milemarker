import 'package:google_maps_flutter/google_maps_flutter.dart';

enum StopType { place, food, fuel, rest, scenic, custom }

enum MealType { breakfast, lunch, dinner, snack }

enum FuelBrand {
  shell,
  chevron,
  exxon,
  bp,
  mobil,
  speedway,
  wawa,
  sheetz,
  costco,
  sams,
  any
}

abstract class Stop {
  final String id;
  final LatLng location;
  final String name;
  final StopType type;
  final int order;
  final Duration? estimatedDuration;
  final TimeWindow? timeWindow;
  final String? notes;

  Stop({
    required this.id,
    required this.location,
    required this.name,
    required this.type,
    required this.order,
    this.estimatedDuration,
    this.timeWindow,
    this.notes,
  });

  Map<String, dynamic> toMap();

  Stop copyWith({
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
  });
}

class TimeWindow {
  final DateTime earliest;
  final DateTime latest;
  final DateTime preferred;

  TimeWindow({
    required this.earliest,
    required this.latest,
    required this.preferred,
  });

  Map<String, dynamic> toMap() => {
        'earliest': earliest.toIso8601String(),
        'latest': latest.toIso8601String(),
        'preferred': preferred.toIso8601String(),
      };

  factory TimeWindow.fromMap(Map<String, dynamic> map) => TimeWindow(
        earliest: DateTime.parse(map['earliest']),
        latest: DateTime.parse(map['latest']),
        preferred: DateTime.parse(map['preferred']),
      );
}
