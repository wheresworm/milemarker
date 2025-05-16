// lib/core/models/route_preferences.dart
class RoutePreferences {
  final bool avoidTolls;
  final bool avoidHighways;
  final bool preferScenic;

  RoutePreferences({
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.preferScenic = false,
  });

  factory RoutePreferences.fromJson(Map<String, dynamic> json) {
    return RoutePreferences(
      avoidTolls: json['avoidTolls'] ?? false,
      avoidHighways: json['avoidHighways'] ?? false,
      preferScenic: json['preferScenic'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'preferScenic': preferScenic,
    };
  }
}
