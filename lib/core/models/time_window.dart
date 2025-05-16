// lib/core/models/time_window.dart
class TimeWindow {
  final DateTime earliest;
  final DateTime latest;
  final DateTime preferred;

  TimeWindow({
    required this.earliest,
    required this.latest,
    required this.preferred,
  });

  Map<String, dynamic> toJson() {
    return {
      'earliest': earliest.toIso8601String(),
      'latest': latest.toIso8601String(),
      'preferred': preferred.toIso8601String(),
    };
  }

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      earliest: DateTime.parse(json['earliest']),
      latest: DateTime.parse(json['latest']),
      preferred: DateTime.parse(json['preferred']),
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
