// lib/core/models/trip.dart
import 'package:milemarker/core/models/user_route.dart';
import 'package:milemarker/core/models/route_optimization.dart';

enum TripStatus { planned, active, paused, completed, cancelled }

class Trip {
  final String id;
  final String title;
  final String routeId;
  final TripStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? actualDuration;
  final double progress;
  final int currentStopIndex;
  final DateTime lastUpdated;
  final String? notes;
  final UserRoute? route;

  Trip({
    required this.id,
    required this.title,
    required this.routeId,
    required this.status,
    this.startTime,
    this.endTime,
    this.actualDuration,
    this.progress = 0.0,
    this.currentStopIndex = 0,
    required this.lastUpdated,
    this.notes,
    this.route,
  });

  bool get isActive =>
      status == TripStatus.active || status == TripStatus.paused;

  OptimizationCriteria? get optimizationCriteria {
    // This could be stored in the trip data
    return null;
  }

  // Add these getters for UI compatibility
  double? get distance => route?.distance;
  Duration? get duration => route?.duration;
  double? get averageSpeed {
    if (route != null &&
        route!.distance != null &&
        route!.duration != null &&
        route!.duration!.inHours > 0) {
      return route!.distance! / route!.duration!.inHours;
    }
    return null;
  }

  Trip copyWith({
    String? id,
    String? title,
    String? routeId,
    TripStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Duration? actualDuration,
    double? progress,
    int? currentStopIndex,
    DateTime? lastUpdated,
    String? notes,
    UserRoute? route,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualDuration: actualDuration ?? this.actualDuration,
      progress: progress ?? this.progress,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
      route: route ?? this.route,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      routeId: json['routeId'] as String,
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TripStatus.planned,
      ),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      actualDuration: json['actualDuration'] != null
          ? Duration(seconds: json['actualDuration'] as int)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentStopIndex: json['currentStopIndex'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      notes: json['notes'] as String?,
      route: json['route'] != null
          ? UserRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'routeId': routeId,
      'status': status.toString().split('.').last,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actualDuration': actualDuration?.inSeconds,
      'progress': progress,
      'currentStopIndex': currentStopIndex,
      'lastUpdated': lastUpdated.toIso8601String(),
      'notes': notes,
      'route': route?.toJson(),
    };
  }
}
