import 'user_route.dart';

class Trip {
  final String id;
  final String routeId;
  final UserRoute? route;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;
  final double? distance; // actual miles driven
  final Duration? duration; // actual time taken
  final double? averageSpeed;
  final double? maxSpeed;
  final Map<String, dynamic>? analytics;

  Trip({
    String? id,
    required this.routeId,
    this.route,
    required this.startTime,
    this.endTime,
    required this.status,
    this.distance,
    this.duration,
    this.averageSpeed,
    this.maxSpeed,
    this.analytics,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Trip copyWith({
    String? id,
    String? routeId,
    UserRoute? route,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
    double? distance,
    Duration? duration,
    double? averageSpeed,
    double? maxSpeed,
    Map<String, dynamic>? analytics,
  }) {
    return Trip(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      route: route ?? this.route,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      analytics: analytics ?? this.analytics,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'route': route?.toJson(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.toString().split('.').last,
        'distance': distance,
        'duration': duration?.inMinutes,
        'averageSpeed': averageSpeed,
        'maxSpeed': maxSpeed,
        'analytics': analytics,
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      routeId: json['routeId'],
      route: json['route'] != null ? UserRoute.fromJson(json['route']) : null,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: TripStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
      ),
      distance: json['distance']?.toDouble(),
      duration:
          json['duration'] != null ? Duration(minutes: json['duration']) : null,
      averageSpeed: json['averageSpeed']?.toDouble(),
      maxSpeed: json['maxSpeed']?.toDouble(),
      analytics: json['analytics'],
    );
  }
}

enum TripStatus { planning, active, paused, completed, cancelled }
