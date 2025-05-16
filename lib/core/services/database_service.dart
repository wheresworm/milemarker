// lib/core/services/database_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/food_stop.dart';
import '../models/fuel_stop.dart';
import '../models/favorite_route.dart';
import '../models/route_template.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import '../models/time_window.dart'; // For TimeWindow
import '../models/user_route.dart'; // For UserRoute
import '../models/route_preferences.dart'; // For RoutePreferences

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
        routeId TEXT NOT NULL,
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
        description TEXT,
        stops TEXT NOT NULL,
        preferences TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create user_routes table
    await db.execute('''
      CREATE TABLE user_routes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        startPoint TEXT NOT NULL,
        endPoint TEXT NOT NULL,
        stops TEXT NOT NULL,
        distance REAL,
        duration INTEGER,
        createdAt TEXT NOT NULL,
        lastUsed TEXT,
        useCount INTEGER DEFAULT 0,
        notes TEXT
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
        'startedAt': trip.startTime?.toIso8601String(),
        'completedAt': trip.endTime?.toIso8601String(),
        'totalDistance':
            trip.distance, // Changed from totalDistance to distance
        'totalDuration':
            trip.duration?.inSeconds, // Changed from totalDuration to duration
        'routeData':
            trip.route != null ? jsonEncode(trip.route!.toJson()) : null,
        'lastUpdated': trip.lastUpdated.toIso8601String(),
        'routeId': trip.routeId,
      },
    );

    // Insert stops if they exist
    if (trip.route?.stops != null) {
      // Changed from trip.stops to trip.route?.stops
      for (final stop in trip.route!.stops) {
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
        'startedAt': trip.startTime?.toIso8601String(),
        'completedAt': trip.endTime?.toIso8601String(),
        'totalDistance':
            trip.distance, // Changed from totalDistance to distance
        'totalDuration':
            trip.duration?.inSeconds, // Changed from totalDuration to duration
        'routeData':
            trip.route != null ? jsonEncode(trip.route!.toJson()) : null,
        'lastUpdated': trip.lastUpdated.toIso8601String(),
        'routeId': trip.routeId,
      },
      where: 'id = ?',
      whereArgs: [trip.id],
    );

    // Update stops
    await db.delete('stops', where: 'tripId = ?', whereArgs: [trip.id]);
    if (trip.route?.stops != null) {
      // Changed from trip.stops to trip.route?.stops
      for (final stop in trip.route!.stops) {
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

      UserRoute? route;
      if (tripMap['routeData'] != null) {
        route = UserRoute.fromJson(jsonDecode(tripMap['routeData'] as String));
        // Update route with stops if needed
        if (route.stops.isEmpty && stops.isNotEmpty) {
          route = route.copyWith(
            stops: stops,
            // Pass the distance and duration from the DB to the route
            distance: tripMap['totalDistance'] != null
                ? (tripMap['totalDistance'] as num).toDouble()
                : null,
            duration: tripMap['totalDuration'] != null
                ? Duration(seconds: tripMap['totalDuration'] as int)
                : null,
          );
        }
      }

      return Trip(
        id: tripId,
        title: tripMap['title'] as String,
        routeId: tripMap['routeId'] as String,
        status: TripStatus.values.firstWhere(
          (s) => s.toString().split('.').last == tripMap['status'],
        ),
        startTime: tripMap['startedAt'] != null
            ? DateTime.parse(tripMap['startedAt'] as String)
            : null,
        endTime: tripMap['completedAt'] != null
            ? DateTime.parse(tripMap['completedAt'] as String)
            : null,
        lastUpdated: DateTime.parse(tripMap['lastUpdated'] as String),
        route: route,
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

    UserRoute? route;
    if (tripMap['routeData'] != null) {
      route = UserRoute.fromJson(jsonDecode(tripMap['routeData'] as String));
      // Update route with stops if needed
      if (route.stops.isEmpty && stops.isNotEmpty) {
        route = route.copyWith(
          stops: stops,
          // Pass the distance and duration from the DB to the route
          distance: tripMap['totalDistance'] != null
              ? (tripMap['totalDistance'] as num).toDouble()
              : null,
          duration: tripMap['totalDuration'] != null
              ? Duration(seconds: tripMap['totalDuration'] as int)
              : null,
        );
      }
    }

    return Trip(
      id: tripId,
      title: tripMap['title'] as String,
      routeId: tripMap['routeId'] as String,
      status: TripStatus.values.firstWhere(
        (s) => s.toString().split('.').last == tripMap['status'],
      ),
      startTime: tripMap['startedAt'] != null
          ? DateTime.parse(tripMap['startedAt'] as String)
          : null,
      endTime: tripMap['completedAt'] != null
          ? DateTime.parse(tripMap['completedAt'] as String)
          : null,
      lastUpdated: DateTime.parse(tripMap['lastUpdated'] as String),
      route: route,
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
        'location': jsonEncode({
          'latitude': stop.location.latitude,
          'longitude': stop.location.longitude,
        }),
        'order_index': stop.order,
        'estimatedDuration': stop.estimatedDuration.inMinutes,
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

    final result = <Stop>[];

    for (final stopMap in stops) {
      final locationMap =
          jsonDecode(stopMap['location'] as String) as Map<String, dynamic>;
      final timeWindowString = stopMap['timeWindow'] as String?;
      final timeWindowMap = timeWindowString != null
          ? jsonDecode(timeWindowString) as Map<String, dynamic>
          : null;

      final baseStop = Stop(
        id: stopMap['id'] as String,
        name: stopMap['name'] as String,
        location: LatLng(
          locationMap['latitude'] as double,
          locationMap['longitude'] as double,
        ),
        order: stopMap['order_index'] as int,
        estimatedDuration: stopMap['estimatedDuration'] != null
            ? Duration(minutes: stopMap['estimatedDuration'] as int)
            : Duration.zero,
        timeWindow: timeWindowMap != null
            ? TimeWindow(
                earliest: DateTime.parse(timeWindowMap['earliest'] as String),
                latest: DateTime.parse(timeWindowMap['latest'] as String),
                preferred: DateTime.parse(timeWindowMap['preferred'] as String),
              )
            : null,
        notes: stopMap['notes'] as String?,
      );

      final stopType = stopMap['type'] as String;

      if (stopType == 'food') {
        result.add(FoodStop(
          id: baseStop.id,
          name: baseStop.name,
          location: baseStop.location,
          order: baseStop.order,
          estimatedDuration: baseStop.estimatedDuration,
          timeWindow: baseStop.timeWindow,
          notes: baseStop.notes,
          mealType: MealType.lunch, // Default value
          cuisine: '',
          priceLevel: 2,
        ));
      } else if (stopType == 'fuel') {
        result.add(FuelStop(
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
          fuelLevel: 0.0,
        ));
      } else {
        result.add(baseStop);
      }
    }

    return result;
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

    final result = <FavoriteRoute>[];

    for (final routeMap in routes) {
      result.add(FavoriteRoute(
        id: routeMap['id'] as String,
        name: routeMap['name'] as String,
        routeData: UserRoute.fromJson(
          jsonDecode(routeMap['routeData'] as String),
        ),
        lastUsed: routeMap['lastUsed'] != null
            ? DateTime.parse(routeMap['lastUsed'] as String)
            : null,
        useCount: routeMap['useCount'] as int,
      ));
    }

    return result;
  }

  // User Route methods - Fixed methods that were missing
  Future<List<UserRoute>> getUserRoutes() async {
    try {
      final db = await database;
      final routes = await db.query('user_routes', orderBy: 'lastUsed DESC');

      final result = <UserRoute>[];

      for (final routeMap in routes) {
        final stopsJson = jsonDecode(routeMap['stops'] as String) as List;

        result.add(UserRoute(
          id: routeMap['id'] as String,
          title: routeMap['title'] as String,
          startPoint: routeMap['startPoint'] as String,
          endPoint: routeMap['endPoint'] as String,
          stops: stopsJson
              .map<Stop>((s) => Stop.fromJson(s as Map<String, dynamic>))
              .toList(),
          distance: routeMap['distance'] != null
              ? (routeMap['distance'] as num).toDouble()
              : null,
          duration: routeMap['duration'] != null
              ? Duration(seconds: routeMap['duration'] as int)
              : null,
          createdAt: DateTime.parse(routeMap['createdAt'] as String),
          lastUsed: routeMap['lastUsed'] != null
              ? DateTime.parse(routeMap['lastUsed'] as String)
              : null,
          useCount: routeMap['useCount'] as int,
          notes: routeMap['notes'] as String?,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('Error getting routes: $e');
      return [];
    }
  }

  Future<void> saveUserRoute(UserRoute route) async {
    try {
      final db = await database;
      await db.insert(
        'user_routes',
        {
          'id': route.id,
          'title': route.title,
          'startPoint': route.startPoint,
          'endPoint': route.endPoint,
          'stops': jsonEncode(route.stops.map((s) => s.toJson()).toList()),
          'distance': route.distance,
          'duration': route.duration?.inSeconds,
          'createdAt': route.createdAt.toIso8601String(),
          'lastUsed': route.lastUsed?.toIso8601String(),
          'useCount': route.useCount, // Remove the ?? 0 if not needed
          'notes': route.notes,
        },
      );
    } catch (e) {
      debugPrint('Error saving route: $e');
      rethrow;
    }
  }

  Future<void> updateUserRoute(UserRoute route) async {
    try {
      final db = await database;
      await db.update(
        'user_routes',
        {
          'title': route.title,
          'startPoint': route.startPoint,
          'endPoint': route.endPoint,
          'stops': jsonEncode(route.stops.map((s) => s.toJson()).toList()),
          'distance': route.distance,
          'duration': route.duration?.inSeconds,
          'lastUsed': route.lastUsed?.toIso8601String(),
          'useCount': route.useCount, // Remove the ?? 0 if not needed
          'notes': route.notes,
        },
        where: 'id = ?',
        whereArgs: [route.id],
      );
    } catch (e) {
      debugPrint('Error updating route: $e');
      rethrow;
    }
  }

  Future<void> deleteUserRoute(String routeId) async {
    try {
      final db = await database;
      await db.delete(
        'user_routes',
        where: 'id = ?',
        whereArgs: [routeId],
      );
    } catch (e) {
      debugPrint('Error deleting route: $e');
      rethrow; // Changed from throw e to rethrow
    }
  }

  // Route template methods
  Future<void> insertRouteTemplate(RouteTemplate template) async {
    final db = await database;
    await db.insert(
      'route_templates',
      {
        'id': template.id,
        'name': template.name,
        'description': template.description,
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

    final result = <RouteTemplate>[];

    for (final templateMap in templates) {
      final stopsJson = jsonDecode(templateMap['stops'] as String) as List;
      final preferencesJson = templateMap['preferences'] != null
          ? jsonDecode(templateMap['preferences'] as String)
              as Map<String, dynamic>
          : null;

      result.add(RouteTemplate(
        id: templateMap['id'] as String,
        name: templateMap['name'] as String,
        description: templateMap['description'] as String? ?? '',
        stops: stopsJson
            .map<Stop>((s) => Stop.fromJson(s as Map<String, dynamic>))
            .toList(),
        preferences: preferencesJson != null
            ? RoutePreferences(
                avoidTolls: preferencesJson['avoidTolls'] as bool? ?? false,
                avoidHighways:
                    preferencesJson['avoidHighways'] as bool? ?? false,
                preferScenic: preferencesJson['preferScenic'] as bool? ?? false,
              )
            : null,
        createdAt: DateTime.parse(templateMap['createdAt'] as String),
      ));
    }

    return result;
  }

  // Trip methods that were referenced in the analyzer but were missing
  Future<void> saveTrip(Trip trip) async {
    return insertTrip(trip);
  }
}
