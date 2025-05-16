import 'meal_preferences.dart';

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
  final double? currentFuelLevel; // Added

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
    this.currentFuelLevel, // Initialize
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
    double? currentFuelLevel,
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
      currentFuelLevel: currentFuelLevel ?? this.currentFuelLevel,
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
        'currentFuelLevel': currentFuelLevel,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'],
      name: json['name'],
      mpg: (json['mpg'] as num?)?.toDouble() ?? 0.0,
      tankSize: (json['tankSize'] as num?)?.toDouble() ?? 0.0,
      fuelType: FuelType.values.firstWhere(
        (t) => t.toString().split('.').last == json['fuelType'],
        orElse: () => FuelType.regular,
      ),
      make: json['make'],
      model: json['model'],
      year: json['year'] as int?,
      licensePlate: json['licensePlate'],
      preferredGasStations: json['preferredGasStations'] != null
          ? List<String>.from(json['preferredGasStations'] as List)
          : null,
      avoidTolls: json['avoidTolls'] as bool? ?? false,
      cruisingSpeed: (json['cruisingSpeed'] as num?)?.toDouble() ?? 65.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentFuelLevel: (json['currentFuelLevel'] as num?)?.toDouble(),
    );
  }
}

enum FuelType { regular, midgrade, premium, diesel, electric }

class UserPreferences {
  final String id;
  final String userId;
  final VehicleProfile? vehicleProfile;
  final MealPreferences? mealPreferences;
  final RoutePreferences routePreferences;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;
  final DateTime? lastModified;

  UserPreferences({
    String? id,
    required this.userId,
    this.vehicleProfile,
    this.mealPreferences,
    RoutePreferences? routePreferences,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
    this.lastModified,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        routePreferences = routePreferences ?? RoutePreferences(),
        notificationPreferences =
            notificationPreferences ?? NotificationPreferences(),
        createdAt = createdAt ?? DateTime.now();

  UserPreferences copyWith({
    String? id,
    String? userId,
    VehicleProfile? vehicleProfile,
    MealPreferences? mealPreferences,
    RoutePreferences? routePreferences,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleProfile: vehicleProfile ?? this.vehicleProfile,
      mealPreferences: mealPreferences ?? this.mealPreferences,
      routePreferences: routePreferences ?? this.routePreferences,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'vehicleProfile': vehicleProfile?.toJson(),
        'mealPreferences': mealPreferences?.toJson(),
        'routePreferences': routePreferences.toJson(),
        'notificationPreferences': notificationPreferences.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'],
      userId: json['userId'],
      vehicleProfile: json['vehicleProfile'] != null
          ? VehicleProfile.fromJson(json['vehicleProfile'])
          : null,
      mealPreferences: json['mealPreferences'] != null
          ? MealPreferences.fromJson(json['mealPreferences'])
          : null,
      routePreferences: json['routePreferences'] != null
          ? RoutePreferences.fromJson(json['routePreferences'])
          : RoutePreferences(),
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(json['notificationPreferences'])
          : NotificationPreferences(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }
}

class RoutePreferences {
  final bool avoidHighways;
  final bool avoidTolls;
  final bool preferScenic;
  final bool fuelEfficient;
  final double maxSpeedLimit;
  final double preferredCruisingSpeed;

  RoutePreferences({
    this.avoidHighways = false,
    this.avoidTolls = false,
    this.preferScenic = false,
    this.fuelEfficient = false,
    this.maxSpeedLimit = 80.0,
    this.preferredCruisingSpeed = 65.0,
  });

  Map<String, dynamic> toJson() => {
        'avoidHighways': avoidHighways,
        'avoidTolls': avoidTolls,
        'preferScenic': preferScenic,
        'fuelEfficient': fuelEfficient,
        'maxSpeedLimit': maxSpeedLimit,
        'preferredCruisingSpeed': preferredCruisingSpeed,
      };

  factory RoutePreferences.fromJson(Map<String, dynamic> json) {
    return RoutePreferences(
      avoidHighways: json['avoidHighways'] ?? false,
      avoidTolls: json['avoidTolls'] ?? false,
      preferScenic: json['preferScenic'] ?? false,
      fuelEfficient: json['fuelEfficient'] ?? false,
      maxSpeedLimit: json['maxSpeedLimit']?.toDouble() ?? 80.0,
      preferredCruisingSpeed:
          json['preferredCruisingSpeed']?.toDouble() ?? 65.0,
    );
  }
}

class NotificationPreferences {
  final bool mealReminders;
  final bool fuelReminders;
  final bool trafficAlerts;
  final bool milestoneNotifications;
  final int reminderMinutesBefore;

  NotificationPreferences({
    this.mealReminders = true,
    this.fuelReminders = true,
    this.trafficAlerts = true,
    this.milestoneNotifications = true,
    this.reminderMinutesBefore = 30,
  });

  Map<String, dynamic> toJson() => {
        'mealReminders': mealReminders,
        'fuelReminders': fuelReminders,
        'trafficAlerts': trafficAlerts,
        'milestoneNotifications': milestoneNotifications,
        'reminderMinutesBefore': reminderMinutesBefore,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      mealReminders: json['mealReminders'] ?? true,
      fuelReminders: json['fuelReminders'] ?? true,
      trafficAlerts: json['trafficAlerts'] ?? true,
      milestoneNotifications: json['milestoneNotifications'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 30,
    );
  }
}
