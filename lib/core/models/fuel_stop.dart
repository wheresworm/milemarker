import 'package:milemarker/core/models/stop.dart';
import 'package:milemarker/core/models/time_window.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FuelStop extends Stop {
  final double fuelLevel;
  final String brand;
  final double pricePerGallon;
  final String fuelType;
  final double currentPrice;

  // Updated to use super parameters
  FuelStop({
    required super.id,
    required super.name,
    required super.location,
    required super.order,
    required this.fuelLevel,
    this.brand = 'Any',
    this.fuelType = 'regular',
    this.pricePerGallon = 0.0,
    this.currentPrice = 0.0,
    super.estimatedDuration = const Duration(minutes: 10),
    super.timeWindow,
    super.notes,
  });

  @override
  StopType get stopType => StopType.fuel;

  @override
  String get categoryIcon => 'local_gas_station';

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'fuelLevel': fuelLevel,
      'brand': brand,
      'pricePerGallon': pricePerGallon,
      'fuelType': fuelType,
      'currentPrice': currentPrice,
    };
  }

  factory FuelStop.fromJson(Map<String, dynamic> json) {
    return FuelStop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      order: json['order'] as int,
      fuelLevel: (json['fuelLevel'] as num).toDouble(),
      brand: json['brand'] as String? ?? 'Any',
      pricePerGallon: (json['pricePerGallon'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: Duration(
        minutes: json['estimatedDuration'] as int? ?? 10,
      ),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      fuelType: json['fuelType'] as String? ?? 'regular',
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
