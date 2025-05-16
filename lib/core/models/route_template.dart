// lib/core/models/route_template.dart
import 'package:milemarker/core/models/stop.dart';
import 'package:milemarker/core/models/route_preferences.dart';

class RouteTemplate {
  final String id;
  final String name;
  final String description;
  final List<Stop> stops;
  final RoutePreferences? preferences;
  final DateTime createdAt;

  RouteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    this.preferences,
    required this.createdAt,
  });

  factory RouteTemplate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> stopsJson = json['stops'] ?? [];

    return RouteTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      stops: stopsJson.map((stop) => Stop.fromJson(stop)).toList(),
      preferences: json['preferences'] != null
          ? RoutePreferences.fromJson(json['preferences'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'preferences': preferences?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
