// lib/core/models/favorite_route.dart

import 'package:milemarker/core/models/user_route.dart';

class FavoriteRoute {
  final String id;
  final String name;
  final UserRoute routeData;
  final String? notes;
  final DateTime? lastUsed;
  final int useCount;

  FavoriteRoute({
    String? id,
    required this.name,
    required this.routeData,
    this.notes,
    this.useCount = 0,
    this.lastUsed,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  FavoriteRoute copyWith({
    String? id,
    String? name,
    UserRoute? routeData,
    String? notes,
    int? useCount,
    DateTime? lastUsed,
  }) {
    return FavoriteRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      routeData: routeData ?? this.routeData,
      notes: notes ?? this.notes,
      useCount: useCount ?? this.useCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'routeData': routeData.toJson(),
        'notes': notes,
        'useCount': useCount,
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      id: json['id'],
      name: json['name'],
      routeData: UserRoute.fromJson(json['routeData']),
      notes: json['notes'],
      useCount: json['useCount'] ?? 0,
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }
}
