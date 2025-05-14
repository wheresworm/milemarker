import 'package:flutter/material.dart';

class TimeWindow {
  final DateTime? earliest;
  final TimeRange? preferred;
  final DateTime? latest;

  TimeWindow({
    this.earliest,
    this.preferred,
    this.latest,
  });

  Map<String, dynamic> toJson() => {
        'earliest': earliest?.toIso8601String(),
        'preferred': preferred?.toJson(),
        'latest': latest?.toIso8601String(),
      };

  Map<String, dynamic> toMap() => toJson(); // Alias for database compatibility

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      earliest:
          json['earliest'] != null ? DateTime.parse(json['earliest']) : null,
      preferred: json['preferred'] != null
          ? TimeRange.fromJson(json['preferred'])
          : null,
      latest: json['latest'] != null ? DateTime.parse(json['latest']) : null,
    );
  }
}

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
}
