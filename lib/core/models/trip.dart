import '../utils/location_point.dart';

class Trip {
  final int? id;
  final String? title;
  final String? category;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance;
  final Duration duration;
  final List<LocationPoint> route;
  final double averageSpeed;
  final double maxSpeed;
  final double totalElevationGain;
  final String? notes;
  final List<String>? photos;
  final Map<String, dynamic>? metadata;

  Trip({
    this.id,
    this.title,
    this.category,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.duration,
    required this.route,
    required this.averageSpeed,
    required this.maxSpeed,
    this.totalElevationGain = 0.0,
    this.notes,
    this.photos,
    this.metadata,
  });

  // Create a trip from database map
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime:
          map['end_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
              : null,
      distance: map['distance'],
      duration: Duration(seconds: map['duration']),
      route:
          (map['route'] as List<dynamic>)
              .map((point) => LocationPoint.fromMap(point))
              .toList(),
      averageSpeed: map['average_speed'],
      maxSpeed: map['max_speed'],
      totalElevationGain: map['total_elevation_gain'] ?? 0.0,
      notes: map['notes'],
      photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
      metadata: map['metadata'],
    );
  }

  // Convert trip to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'distance': distance,
      'duration': duration.inSeconds,
      'route': route.map((point) => point.toMap()).toList(),
      'average_speed': averageSpeed,
      'max_speed': maxSpeed,
      'total_elevation_gain': totalElevationGain,
      'notes': notes,
      'photos': photos,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  Trip copyWith({
    int? id,
    String? title,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    Duration? duration,
    List<LocationPoint>? route,
    double? averageSpeed,
    double? maxSpeed,
    double? totalElevationGain,
    String? notes,
    List<String>? photos,
    Map<String, dynamic>? metadata,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      totalElevationGain: totalElevationGain ?? this.totalElevationGain,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      metadata: metadata ?? this.metadata,
    );
  }
}
