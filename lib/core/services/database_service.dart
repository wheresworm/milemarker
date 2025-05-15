// lib/core/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_route.dart';
import '../models/trip.dart';
import '../models/stop.dart';
import '../models/settings.dart';
import '../models/place_stop.dart';
import '../models/food_stop.dart';
import '../models/fuel_stop.dart';
import '../models/place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'milemarker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Routes table
    await db.execute('''
      CREATE TABLE routes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        startPoint TEXT NOT NULL,
        endPoint TEXT NOT NULL,
        distance REAL,
        duration INTEGER,
        createdAt INTEGER NOT NULL,
        lastUsed INTEGER,
        useCount INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    // Stops table
    await db.execute('''
      CREATE TABLE stops(
        id TEXT PRIMARY KEY,
        routeId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        orderIndex INTEGER NOT NULL,
        estimatedDuration INTEGER NOT NULL,
        notes TEXT,
        stopData TEXT,
        FOREIGN KEY (routeId) REFERENCES routes (id) ON DELETE CASCADE
      )
    ''');

    // Trips table
    await db.execute('''
      CREATE TABLE trips(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        routeId TEXT NOT NULL,
        status TEXT NOT NULL,
        startTime INTEGER,
        endTime INTEGER,
        actualDuration INTEGER,
        progress REAL DEFAULT 0.0,
        currentStopIndex INTEGER DEFAULT 0,
        lastUpdated INTEGER NOT NULL,
        trackingData TEXT,
        notes TEXT,
        FOREIGN KEY (routeId) REFERENCES routes (id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY,
        theme TEXT NOT NULL,
        notifications INTEGER NOT NULL,
        autoSave INTEGER NOT NULL,
        defaultMapType TEXT NOT NULL,
        unitSystem TEXT NOT NULL,
        currentVehicleId TEXT,
        settingsData TEXT
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'theme': 'system',
      'notifications': 1,
      'autoSave': 1,
      'defaultMapType': 'normal',
      'unitSystem': 'imperial',
    });
  }

  // Route methods
  Future<void> saveRoute(UserRoute route) async {
    final db = await database;
    await db.insert(
      'routes',
      {
        'id': route.id,
        'title': route.title,
        'startPoint': route.startPoint,
        'endPoint': route.endPoint,
        'distance': route.distance,
        'duration': route.duration?.inSeconds,
        'createdAt': route.createdAt.millisecondsSinceEpoch,
        'lastUsed': route.lastUsed?.millisecondsSinceEpoch,
        'useCount': route.useCount,
        'notes': route.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save stops
    await _saveStopsForRoute(route.id, route.stops);
  }

  Future<List<UserRoute>> getRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('routes', orderBy: 'lastUsed DESC');

    List<UserRoute> routes = [];
    for (var map in maps) {
      final stops = await _getStopsForRoute(map['id'] as String);
      routes.add(UserRoute(
        id: map['id'] as String,
        title: map['title'] as String,
        startPoint: map['startPoint'] as String,
        endPoint: map['endPoint'] as String,
        stops: stops,
        distance: map['distance'] as double?,
        duration: map['duration'] != null
            ? Duration(seconds: map['duration'] as int)
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        lastUsed: map['lastUsed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] as int)
            : null,
        useCount: map['useCount'] as int,
        notes: map['notes'] as String?,
      ));
    }

    return routes;
  }

  Future<void> updateRoute(UserRoute route) async {
    await saveRoute(route);
  }

  Future<void> deleteRoute(String routeId) async {
    final db = await database;
    await db.delete(
      'routes',
      where: 'id = ?',
      whereArgs: [routeId],
    );
  }

  // Trip methods
  Future<String> saveTrip(Trip trip) async {
    final db = await database;
    await db.insert(
      'trips',
      {
        'id': trip.id,
        'title': trip.title,
        'routeId': trip.routeId,
        'status': trip.status.toString().split('.').last,
        'startTime': trip.startTime?.millisecondsSinceEpoch,
        'endTime': trip.endTime?.millisecondsSinceEpoch,
        'actualDuration': trip.actualDuration?.inSeconds,
        'progress': trip.progress,
        'currentStopIndex': trip.currentStopIndex,
        'lastUpdated': trip.lastUpdated.millisecondsSinceEpoch,
        'notes': trip.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return trip.id;
  }

  Future<List<Trip>> getTrips() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('trips', orderBy: 'lastUpdated DESC');

    return maps
        .map((map) => Trip(
              id: map['id'] as String,
              title: map['title'] as String,
              routeId: map['routeId'] as String,
              status: TripStatus.values.firstWhere(
                (e) => e.toString().split('.').last == map['status'],
                orElse: () => TripStatus.planned,
              ),
              startTime: map['startTime'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int)
                  : null,
              endTime: map['endTime'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
                  : null,
              actualDuration: map['actualDuration'] != null
                  ? Duration(seconds: map['actualDuration'] as int)
                  : null,
              progress: map['progress'] as double,
              currentStopIndex: map['currentStopIndex'] as int,
              lastUpdated: DateTime.fromMillisecondsSinceEpoch(
                  map['lastUpdated'] as int),
              notes: map['notes'] as String?,
            ))
        .toList();
  }

  // Add these missing methods
  Future<List<Trip>> getAllTrips() => getTrips();

  Future<void> deleteTrip(String tripId) async {
    final db = await database;
    await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  Future<void> updateTrip(Trip trip) async {
    await saveTrip(trip);
  }

  Future<void> insertTrip(Trip trip) async {
    await saveTrip(trip);
  }

  // Helper methods for stops
  Future<void> _saveStopsForRoute(String routeId, List<Stop> stops) async {
    final db = await database;

    // Delete existing stops
    await db.delete('stops', where: 'routeId = ?', whereArgs: [routeId]);

    // Insert new stops
    for (var stop in stops) {
      await db.insert('stops', {
        'id': stop.id,
        'routeId': routeId,
        'name': stop.name,
        'type': stop.stopType.toString().split('.').last,
        'latitude': stop.location.latitude,
        'longitude': stop.location.longitude,
        'orderIndex': stop.order,
        'estimatedDuration': stop.estimatedDuration.inMinutes,
        'notes': stop.notes,
        'stopData': _getStopData(stop),
      });
    }
  }

  Future<List<Stop>> _getStopsForRoute(String routeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stops',
      where: 'routeId = ?',
      whereArgs: [routeId],
      orderBy: 'orderIndex',
    );

    return maps.map((map) {
      final type = StopType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      );

      final location = LatLng(
        map['latitude'] as double,
        map['longitude'] as double,
      );

      switch (type) {
        case StopType.place:
          return PlaceStop(
            id: map['id'] as String,
            name: map['name'] as String,
            location: location,
            order: map['orderIndex'] as int,
            placeType: PlaceType.other,
            estimatedDuration:
                Duration(minutes: map['estimatedDuration'] as int),
            notes: map['notes'] as String?,
          );
        case StopType.food:
          // Parse food stop data
          return FoodStop(
            id: map['id'] as String,
            name: map['name'] as String,
            location: location,
            order: map['orderIndex'] as int,
            mealType: MealType.breakfast, // Default, should parse from stopData
            estimatedDuration:
                Duration(minutes: map['estimatedDuration'] as int),
            notes: map['notes'] as String?,
          );
        case StopType.fuel:
          return FuelStop(
            id: map['id'] as String,
            name: map['name'] as String,
            location: location,
            order: map['orderIndex'] as int,
            fuelLevel: 0.5, // Default, should parse from stopData
            estimatedDuration:
                Duration(minutes: map['estimatedDuration'] as int),
            notes: map['notes'] as String?,
          );
        default:
          return PlaceStop(
            id: map['id'] as String,
            name: map['name'] as String,
            location: location,
            order: map['orderIndex'] as int,
            placeType: PlaceType.other,
            estimatedDuration:
                Duration(minutes: map['estimatedDuration'] as int),
            notes: map['notes'] as String?,
          );
      }
    }).toList();
  }

  String _getStopData(Stop stop) {
    if (stop is FoodStop) {
      return '${stop.mealType.toString().split('.').last},${stop.preferences.join(',')}';
    } else if (stop is FuelStop) {
      return '${stop.fuelLevel},${stop.brand},${stop.pricePerGallon}';
    }
    return '';
  }

  // Settings methods
  Future<Settings> getSettings() async {
    final db = await database;
    final maps = await db.query('settings', limit: 1);

    if (maps.isEmpty) {
      // Return default settings
      return Settings();
    }

    final map = maps.first;
    return Settings(
      theme: map['theme'] as String,
      notifications: map['notifications'] == 1,
      autoSave: map['autoSave'] == 1,
      defaultMapType: map['defaultMapType'] as String,
      unitSystem: map['unitSystem'] as String,
    );
  }

  Future<void> updateSettings(Settings settings) async {
    final db = await database;
    await db.update(
      'settings',
      {
        'theme': settings.theme,
        'notifications': settings.notifications ? 1 : 0,
        'autoSave': settings.autoSave ? 1 : 0,
        'defaultMapType': settings.defaultMapType,
        'unitSystem': settings.unitSystem,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
