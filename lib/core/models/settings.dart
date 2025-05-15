// lib/core/models/settings.dart
class Settings {
  final String theme;
  final bool notifications;
  final bool autoSave;
  final String defaultMapType;
  final String unitSystem;

  Settings({
    this.theme = 'system',
    this.notifications = true,
    this.autoSave = true,
    this.defaultMapType = 'normal',
    this.unitSystem = 'imperial',
  });

  Settings copyWith({
    String? theme,
    bool? notifications,
    bool? autoSave,
    String? defaultMapType,
    String? unitSystem,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      autoSave: autoSave ?? this.autoSave,
      defaultMapType: defaultMapType ?? this.defaultMapType,
      unitSystem: unitSystem ?? this.unitSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications': notifications,
      'autoSave': autoSave,
      'defaultMapType': defaultMapType,
      'unitSystem': unitSystem,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      theme: json['theme'] ?? 'system',
      notifications: json['notifications'] ?? true,
      autoSave: json['autoSave'] ?? true,
      defaultMapType: json['defaultMapType'] ?? 'normal',
      unitSystem: json['unitSystem'] ?? 'imperial',
    );
  }
}
