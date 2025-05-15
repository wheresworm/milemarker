// lib/core/models/vehicle.dart
class Vehicle {
  final String id;
  final String name;
  final double mpg;
  final double tankSize;
  final String fuelType;

  Vehicle({
    required this.id,
    required this.name,
    required this.mpg,
    required this.tankSize,
    this.fuelType = 'regular',
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      mpg: (json['mpg'] as num).toDouble(),
      tankSize: (json['tankSize'] as num).toDouble(),
      fuelType: json['fuelType'] as String? ?? 'regular',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mpg': mpg,
      'tankSize': tankSize,
      'fuelType': fuelType,
    };
  }
}
