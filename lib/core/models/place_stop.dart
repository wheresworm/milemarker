import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place.dart';
import 'stop.dart';
import 'time_window.dart';

class PlaceStop extends Stop {
  final PlaceType placeType;
  final String? placeId;
  final String? address;
  final double? rating;
  final String? phoneNumber;

  PlaceStop({
    String? id,
    required String name,
    required LatLng location,
    required int order,
    Duration estimatedDuration = const Duration(minutes: 30),
    TimeWindow? timeWindow,
    String? notes,
    required this.placeType,
    this.placeId,
    this.address,
    this.rating,
    this.phoneNumber,
  }) : super(
          id: id,
          name: name,
          location: location,
          order: order,
          estimatedDuration: estimatedDuration,
          timeWindow: timeWindow,
          notes: notes,
          type: StopType.custom,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'placeType': placeType.toString().split('.').last,
      'placeId': placeId,
      'address': address,
      'rating': rating,
      'phoneNumber': phoneNumber,
    });
    return json;
  }

  factory PlaceStop.fromJson(Map<String, dynamic> json) {
    return PlaceStop(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      order: json['order'],
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'])
          : const Duration(minutes: 30),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      notes: json['notes'],
      placeType: PlaceType.values.firstWhere(
        (t) => t.toString().split('.').last == json['placeType'],
        orElse: () => PlaceType.other,
      ),
      placeId: json['placeId'],
      address: json['address'],
      rating: json['rating']?.toDouble(),
      phoneNumber: json['phoneNumber'],
    );
  }

  @override
  PlaceStop copyWith({
    String? id,
    String? name,
    LatLng? location,
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
    StopType? type,
    PlaceType? placeType,
    String? placeId,
    String? address,
    double? rating,
    String? phoneNumber,
  }) {
    return PlaceStop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      order: order ?? this.order,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      timeWindow: timeWindow ?? this.timeWindow,
      notes: notes ?? this.notes,
      placeType: placeType ?? this.placeType,
      placeId: placeId ?? this.placeId,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
