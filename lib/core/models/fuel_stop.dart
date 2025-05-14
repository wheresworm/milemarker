import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';
import 'time_window.dart';

class FuelStop extends Stop {
  final double gallonsNeeded;
  final String? placeId;

  FuelStop({
    super.id,
    required super.name,
    required super.location,
    required super.order,
    super.estimatedDuration = const Duration(minutes: 15),
    super.timeWindow,
    super.notes,
    required this.gallonsNeeded,
    required this.placeId,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'gallonsNeeded': gallonsNeeded,
      'placeId': placeId,
    });
    return json;
  }

  factory FuelStop.fromJson(Map<String, dynamic> json) {
    return FuelStop(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      order: json['order'],
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'])
          : const Duration(minutes: 15),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      notes: json['notes'],
      gallonsNeeded: json['gallonsNeeded'].toDouble(),
      placeId: json['placeId'],
    );
  }
}
