import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/fuel_stop.dart';
import '../models/favorite_route.dart';
import '../models/route_template.dart';

class DatabaseService {
  static const String _databaseName = 'milemarker.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_databaseName';

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create trips table
    await db.execute('''
      CREATE TABLE trips(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        status TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        totalDistance REAL,
        totalDuration INTEGER,
        routeData TEXT,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Create stops table
    await db.execute('''
      CREATE TABLE stops(
        id TEXT PRIMARY KEY,
        tripId TEXT NOT NULL,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        estimatedDuration INTEGER,
        timeWindow TEXT,
        notes TEXT,
        type TEXT NOT NULL,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Create favorite_routes table
    await db.execute('''
      CREATE TABLE favorite_routes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        routeData TEXT NOT NULL,
        lastUsed TEXT,
        useCount INTEGER DEFAULT 0
      )
    ''');

    // Create route_templates table
    await db.execute('''
      CREATE TABLE route_templates(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        stops TEXT NOT NULL,
        preferences TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Trip methods
  Future<void> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert(
      'trips',
      {
        'id': trip.id,
        'title': trip.title,
        'status': trip.status.toString().split('.').last,
        'startedAt': trip.startedAt?.toIso8601String(),
        'completedAt': trip.completedAt?.toIso8601String(),
        'totalDistance': trip.totalDistance,
        'totalDuration': trip.totalDuration?.inSeconds,
        'routeData':
            trip.route != null ? jsonEncode(trip.route!.toJson()) : null,
        'lastUpdated': trip.lastUpdated.toIso8601String(),
      },
    );

    // Insert stops
    if (trip.stops != null) {
      for (final stop in trip.stops!) {
        await insertStop(trip.id, stop);
      }
    }
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db.update(
      'trips',
      {
        'title': trip.title,
        'status': trip.status.toString().split('.').last,
        'startedAt': trip.startedAt?.toIso8601String(),
        'completedAt': trip.completedAt?.toIso8601String(),
        'totalDistance': trip.totalDistance,
        'totalDuration': trip.totalDuration?.inSeconds,
        'routeData':
            trip.route != null ? jsonEncode(trip.route!.toJson()) : null,
        'lastUpdated': trip.lastUpdated.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [trip.id],
    );

    // Update stops
    await db.delete('stops', where: 'tripId = ?', whereArgs: [trip.id]);
    if (trip.stops != null) {
      for (final stop in trip.stops!) {
        await insertStop(trip.id, stop);
      }
    }
  }

  Future<void> deleteTrip(String tripId) async {
    final db = await database;
    await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final trips = await db.query('trips', orderBy: 'lastUpdated DESC');

    return Future.wait(trips.map((tripMap) async {
      final tripId = tripMap['id'] as String;
      final stops = await getStopsForTrip(tripId);

      return Trip(
        id: tripId,
        title: tripMap['title'] as String,
        status: TripStatus.values.firstWhere(
          (s) => s.toString().split('.').last == tripMap['status'],
        ),
        startedAt: tripMap['startedAt'] != null
            ? DateTime.parse(tripMap['startedAt'] as String)
            : null,
        completedAt: tripMap['completedAt'] != null
            ? DateTime.parse(tripMap['completedAt'] as String)
            : null,
        totalDistance: tripMap['totalDistance'] as double?,
        totalDuration: tripMap['totalDuration'] != null
            ? Duration(seconds: tripMap['totalDuration'] as int)
            : null,
        stops: stops,
        lastUpdated: DateTime.parse(tripMap['lastUpdated'] as String),
      );
    }));
  }

  Future<Trip?> getTripById(String tripId) async {
    final db = await database;
    final trips = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );

    if (trips.isEmpty) return null;

    final tripMap = trips.first;
    final stops = await getStopsForTrip(tripId);

    return Trip(
      id: tripId,
      title: tripMap['title'] as String,
      status: TripStatus.values.firstWhere(
        (s) => s.toString().split('.').last == tripMap['status'],
      ),
      startedAt: tripMap['startedAt'] != null
          ? DateTime.parse(tripMap['startedAt'] as String)
          : null,
      completedAt: tripMap['completedAt'] != null
          ? DateTime.parse(tripMap['completedAt'] as String)
          : null,
      totalDistance: tripMap['totalDistance'] as double?,
      totalDuration: tripMap['totalDuration'] != null
          ? Duration(seconds: tripMap['totalDuration'] as int)
          : null,
      stops: stops,
      lastUpdated: DateTime.parse(tripMap['lastUpdated'] as String),
    );
  }

  // Stop methods
  Future<void> insertStop(String tripId, Stop stop) async {
    final db = await database;

    String stopType = 'place';
    if (stop is FoodStop) {
      stopType = 'food';
    } else if (stop is FuelStop) {
      stopType = 'fuel';
    }

    await db.insert(
      'stops',
      {
        'id': stop.id,
        'tripId': tripId,
        'name': stop.name,
        'location': jsonEncode(stop.location.toJson()),
        'order_index': stop.order,
        'estimatedDuration': stop.estimatedDuration?.inMinutes,
        'timeWindow': stop.timeWindow != null
            ? jsonEncode(stop.timeWindow!.toJson())
            : null,
        'notes': stop.notes,
        'type': stopType,
      },
    );
  }

  Future<List<Stop>> getStopsForTrip(String tripId) async {
    final db = await database;
    final stops = await db.query(
      'stops',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'order_index ASC',
    );

    return stops.map((stopMap) {
      final location = jsonDecode(stopMap['location'] as String);
      final timeWindow = stopMap['timeWindow'] != null
          ? jsonDecode(stopMap['timeWindow'] as String)
          : null;

      final baseStop = Stop(
        id: stopMap['id'] as String,
        name: stopMap['name'] as String,
        location: LatLng(
          location['latitude'] as double,
          location['longitude'] as double,
        ),
        order: stopMap['order_index'] as int,
        estimatedDuration: stopMap['estimatedDuration'] != null
            ? Duration(minutes: stopMap['estimatedDuration'] as int)
            : null,
        timeWindow: timeWindow != null
            ? TimeWindow(
                earliest: DateTime.parse(timeWindow['earliest']),
                latest: DateTime.parse(timeWindow['latest']),
                preferred: DateTime.parse(timeWindow['preferred']),
              )
            : null,
        notes: stopMap['notes'] as String?,
      );

      final stopType = stopMap['type'] as String;

      if (stopType == 'food') {
        return FoodStop(
          id: baseStop.id,
          name: baseStop.name,
          location: baseStop.location,
          order: baseStop.order,
          estimatedDuration: baseStop.estimatedDuration,
          timeWindow: baseStop.timeWindow,
          notes: baseStop.notes,
          mealType:
              MealType.lunch, // Default value, you might want to store this
          cuisine: '',
          priceLevel: 2,
        );
      } else if (stopType == 'fuel') {
        return FuelStop(
          id: baseStop.id,
          name: baseStop.name,
          location: baseStop.location,
          order: baseStop.order,
          estimatedDuration: baseStop.estimatedDuration,
          timeWindow: baseStop.timeWindow,
          notes: baseStop.notes,
          fuelType: 'regular',
          currentPrice: 0.0,
          brand: '',
        );
      }

      return baseStop;
    }).toList();
  }

  // Favorite route methods
  Future<void> insertFavoriteRoute(FavoriteRoute route) async {
    final db = await database;
    await db.insert(
      'favorite_routes',
      {
        'id': route.id,
        'name': route.name,
        'routeData': jsonEncode(route.routeData.toJson()),
        'lastUsed': route.lastUsed?.toIso8601String(),
        'useCount': route.useCount,
      },
    );
  }

  Future<List<FavoriteRoute>> getAllFavoriteRoutes() async {
    final db = await database;
    final routes = await db.query('favorite_routes', orderBy: 'lastUsed DESC');

    return routes.map((routeMap) {
      return FavoriteRoute(
        id: routeMap['id'] as String,
        name: routeMap['name'] as String,
        routeData: UserRoute.fromJson(
          jsonDecode(routeMap['routeData'] as String),
        ),
        lastUsed: routeMap['lastUsed'] != null
            ? DateTime.parse(routeMap['lastUsed'] as String)
            : null,
        useCount: routeMap['useCount'] as int,
      );
    }).toList();
  }

  // Route template methods
  Future<void> insertRouteTemplate(RouteTemplate template) async {
    final db = await database;
    await db.insert(
      'route_templates',
      {
        'id': template.id,
        'name': template.name,
        'stops': jsonEncode(template.stops.map((s) => s.toJson()).toList()),
        'preferences': template.preferences != null
            ? jsonEncode({
                'avoidTolls': template.preferences!.avoidTolls,
                'avoidHighways': template.preferences!.avoidHighways,
                'preferScenic': template.preferences!.preferScenic,
              })
            : null,
        'createdAt': template.createdAt.toIso8601String(),
      },
    );
  }

  Future<List<RouteTemplate>> getAllRouteTemplates() async {
    final db = await database;
    final templates =
        await db.query('route_templates', orderBy: 'createdAt DESC');

    return templates.map((templateMap) {
      final stopsJson = jsonDecode(templateMap['stops'] as String) as List;
      final preferencesJson = templateMap['preferences'] != null
          ? jsonDecode(templateMap['preferences'] as String)
          : null;

      return RouteTemplate(
        id: templateMap['id'] as String,
        name: templateMap['name'] as String,
        stops: stopsJson.map((s) => Stop.fromJson(s)).toList(),
        preferences: preferencesJson != null
            ? RoutePreferences(
                avoidTolls: preferencesJson['avoidTolls'] ?? false,
                avoidHighways: preferencesJson['avoidHighways'] ?? false,
                preferScenic: preferencesJson['preferScenic'] ?? false,
              )
            : null,
        createdAt: DateTime.parse(templateMap['createdAt'] as String),
      );
    }).toList();
  }
}
