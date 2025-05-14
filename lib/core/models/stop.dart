import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'time_window.dart';

class Stop {
  final String id;
  final String name;
  final LatLng location;
  final int order;
  final Duration estimatedDuration;
  final TimeWindow? timeWindow;
  final String? notes;
  final StopType type;

  Stop({
    String? id,
    required this.name,
    required this.location,
    required this.order,
    this.estimatedDuration = const Duration(minutes: 30),
    this.timeWindow,
    this.notes,
    this.type = StopType.custom,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Stop copyWith({
    String? id,
    String? name,
    LatLng? location,
    int? order,
    Duration? estimatedDuration,
    TimeWindow? timeWindow,
    String? notes,
    StopType? type,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      order: order ?? this.order,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      timeWindow: timeWindow ?? this.timeWindow,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'order': order,
        'estimatedDuration': estimatedDuration.inMinutes,
        'timeWindow': timeWindow?.toJson(),
        'notes': notes,
        'type': type.toString().split('.').last,
      };

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: json['name'],
      location: LatLng(json['latitude'], json['longitude']),
      order: json['order'],
      estimatedDuration: Duration(minutes: json['estimatedDuration'] ?? 30),
      timeWindow: json['timeWindow'] != null
          ? TimeWindow.fromJson(json['timeWindow'])
          : null,
      notes: json['notes'],
      type: StopType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => StopType.custom,
      ),
    );
  }
}

enum StopType { origin, destination, meal, fuel, rest, hotel, scenic, custom }
