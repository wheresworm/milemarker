// lib/core/models/route_template.dart
import 'package:milemarker/core/models/user_route.dart';

class RouteTemplate {
  final String id;
  final String name;
  final String description;
  final UserRoute route;

  RouteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.route,
  });

  factory RouteTemplate.fromJson(Map<String, dynamic> json) {
    return RouteTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      route: UserRoute.fromJson(json['route']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'route': route.toJson(),
    };
  }
}
