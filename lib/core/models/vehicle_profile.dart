class VehicleProfile {
  final String id;
  final String name;
  final double mpg; // miles per gallon
  final double tankSize; // gallons
  final FuelType fuelType;
  final String? make;
  final String? model;
  final int? year;
  final String? licensePlate;
  final List<String>? preferredGasStations;
  final bool avoidTolls;
  final double cruisingSpeed; // mph
  final DateTime createdAt;

  VehicleProfile({
    String? id,
    required this.name,
    required this.mpg,
    required this.tankSize,
    this.fuelType = FuelType.regular,
    this.make,
    this.model,
    this.year,
    this.licensePlate,
    this.preferredGasStations,
    this.avoidTolls = false,
    this.cruisingSpeed = 65.0,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  double get range => mpg * tankSize;
  double get safeRange => range * 0.75; // Never go below 1/4 tank

  VehicleProfile copyWith({
    String? id,
    String? name,
    double? mpg,
    double? tankSize,
    FuelType? fuelType,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    List<String>? preferredGasStations,
    bool? avoidTolls,
    double? cruisingSpeed,
    DateTime? createdAt,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      mpg: mpg ?? this.mpg,
      tankSize: tankSize ?? this.tankSize,
      fuelType: fuelType ?? this.fuelType,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      preferredGasStations: preferredGasStations ?? this.preferredGasStations,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      cruisingSpeed: cruisingSpeed ?? this.cruisingSpeed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mpg': mpg,
        'tankSize': tankSize,
        'fuelType': fuelType.toString().split('.').last,
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'preferredGasStations': preferredGasStations,
        'avoidTolls': avoidTolls,
        'cruisingSpeed': cruisingSpeed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'],
      name: json['name'],
      mpg: json['mpg'].toDouble(),
      tankSize: json['tankSize'].toDouble(),
      fuelType: FuelType.values.firstWhere(
        (t) => t.toString().split('.').last == json['fuelType'],
        orElse: () => FuelType.regular,
      ),
      make: json['make'],
      model: json['model'],
      year: json['year'],
      licensePlate: json['licensePlate'],
      preferredGasStations: json['preferredGasStations'] != null
          ? List<String>.from(json['preferredGasStations'])
          : null,
      avoidTolls: json['avoidTolls'] ?? false,
      cruisingSpeed: json['cruisingSpeed']?.toDouble() ?? 65.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum FuelType { regular, midgrade, premium, diesel, electric }
