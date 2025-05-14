class FavoriteRoute {
  final String id;
  final String routeId;
  final String name;
  final String? notes;
  final DateTime savedAt;
  final int usageCount;
  final DateTime? lastUsed;

  FavoriteRoute({
    String? id,
    required this.routeId,
    required this.name,
    this.notes,
    DateTime? savedAt,
    this.usageCount = 0,
    this.lastUsed,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        savedAt = savedAt ?? DateTime.now();

  FavoriteRoute copyWith({
    String? id,
    String? routeId,
    String? name,
    String? notes,
    DateTime? savedAt,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return FavoriteRoute(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      savedAt: savedAt ?? this.savedAt,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'name': name,
        'notes': notes,
        'savedAt': savedAt.toIso8601String(),
        'usageCount': usageCount,
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      id: json['id'],
      routeId: json['routeId'],
      name: json['name'],
      notes: json['notes'],
      savedAt: DateTime.parse(json['savedAt']),
      usageCount: json['usageCount'] ?? 0,
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }
}
