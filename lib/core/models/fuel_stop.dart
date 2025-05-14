import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop.dart';

class FuelStop extends Stop {
  final FuelBrand brand;
  final double pricePerGallon;
  final List<String> amenities; // restroom, food, atm
  final Duration detour;
  final bool hasDiesel;
  final DateTime? priceUpdated;

  FuelStop({
    required String id,
    required LatLng location,
    required String name,
    required int order,
    required this.brand,
    required this.pricePerGallon,
    this.amenities = const [],
    this.detour = Duration.zero,
    this.hasDiesel = false,
    this.priceUpdated,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
  }) : super(
          id: id,
          location: location,
          name: name,
          type: StopType.fuel,
          order: order,
          estimatedDuration: estimatedDuration ?? const Duration(minutes: 10),
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
        'brand': brand.toString(),
        'pricePerGallon': pricePerGallon,
        'amenities': amenities,
        'detour': detour.inSeconds,
        'hasDiesel': hasDiesel,
        'priceUpdated': priceUpdated?.toIso8601String(),
      };

  @override
  FuelStop copyWith({
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
    double? pricePerGallon,
    DateTime? priceUpdated,
  }) =>
      FuelStop(
        id: id,
        location: location,
        name: name,
        order: order ?? this.order,
        brand: brand,
        pricePerGallon: pricePerGallon ?? this.pricePerGallon,
        amenities: amenities,
        detour: detour,
        hasDiesel: hasDiesel,
        priceUpdated: priceUpdated ?? this.priceUpdated,
        estimatedDuration: estimatedDuration ?? this.estimatedDuration,
        timeWindow: timeWindow ?? this.timeWindow,
        notes: notes ?? this.notes,
      );
}
