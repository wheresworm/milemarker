import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';
import 'place.dart';

class PlaceStop extends Stop {
  final Place placeDetails;
  final String? customName;

  PlaceStop({
    required String id,
    required LatLng location,
    required String name,
    required int order,
    required this.placeDetails,
    this.customName,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
  }) : super(
          id: id,
          location: location,
          name: customName ?? name,
          type: StopType.place,
          order: order,
          estimatedDuration: estimatedDuration,
          timeWindow: timeWindow,
          notes: notes,
        );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
        'name': name,
        'type': type.toString(),
        'order': order,
        'estimatedDuration': estimatedDuration?.inSeconds,
        'timeWindow': timeWindow?.toMap(),
        'notes': notes,
        'placeDetails': placeDetails.toMap(),
        'customName': customName,
      };

  @override
  PlaceStop copyWith({
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
    String? customName,
  }) =>
      PlaceStop(
        id: id,
        location: location,
        name: name,
        order: order ?? this.order,
        placeDetails: placeDetails,
        customName: customName ?? this.customName,
        estimatedDuration: estimatedDuration ?? this.estimatedDuration,
        timeWindow: timeWindow ?? this.timeWindow,
        notes: notes ?? this.notes,
      );
}
