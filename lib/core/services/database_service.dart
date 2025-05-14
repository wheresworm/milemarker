import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/trip.dart';
import '../models/route.dart' as route_model;
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<void> init() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        category TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        distance REAL NOT NULL,
        duration INTEGER NOT NULL,
        route TEXT NOT NULL,
        average_speed REAL NOT NULL,
        max_speed REAL NOT NULL,
        total_elevation_gain REAL,
        notes TEXT,
        photos TEXT,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE routes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        stops TEXT NOT NULL,
        departure_time INTEGER NOT NULL,
        optimization TEXT,
        directions TEXT,
        stats TEXT,
        metadata TEXT
      )
    ''');
  }

  Future<int> insertTrip(Trip trip) async {
    final db = _database!;
    final tripMap = trip.toMap();
    // Convert route list to JSON string for storage
    tripMap['route'] = jsonEncode(tripMap['route']);
    return await db.insert('trips', tripMap);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query('trips');

    return List.generate(maps.length, (i) {
      // Parse the route JSON string back to list
      final routeJson = maps[i]['route'] as String;
      final routeList = (jsonDecode(routeJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Create a new map with the parsed route
      final tripMap = Map<String, dynamic>.from(maps[i]);
      tripMap['route'] = routeList;

      return Trip.fromMap(tripMap);
    });
  }

  Future<Trip?> getTrip(int id) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTrip(Trip trip) async {
    final db = _database!;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = _database!;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Route methods
  Future<void> saveRoute(route_model.Route route) async {
    final db = _database!;
    final routeMap = {
      'id': route.id,
      'name': route.name,
      'stops': jsonEncode(route.stops.map((s) => s.toMap()).toList()),
      'departure_time': route.departureTime.millisecondsSinceEpoch,
      'optimization': route.optimization.toString(),
      'directions': route.directions != null
          ? jsonEncode(route.directions!.toMap())
          : null,
      'stats': route.stats != null ? jsonEncode(route.stats!.toMap()) : null,
      'metadata': jsonEncode(route.metadata),
    };

    await db.insert(
      'routes',
      routeMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<route_model.Route?> getRoute(String routeId) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [routeId],
    );

    if (maps.isEmpty) return null;

    // Parse the route from database
    // Note: This is simplified - you'd need proper deserialization
    final map = maps.first;
    return null; // TODO: Implement proper deserialization
  }

  Future<List<route_model.Route>> getAllRoutes() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query('routes');

    // Note: This is simplified - you'd need proper deserialization
    return []; // TODO: Implement proper deserialization
  }
}
