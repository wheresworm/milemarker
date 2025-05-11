// lib/screens/map_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IMPORTANT IMPORT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// This import MUST be exactly the real Maps plugin:
import 'package:google_maps_flutter/google_maps_flutter.dart';
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IMPORTANT IMPORT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv if using it here

// Make sure to import your logger if needed here as well
// import 'utils/logger.dart'; // Uncomment if AppLogger is used directly in map_screen

enum StopType { breakfast, lunch, dinner, custom }

class Stop {
  StopType type;
  String label;
  DateTime time;
  Duration dwell;
  LatLng? location;
  String? name;
  String? address;
  TextEditingController searchController;

  Stop({
    required this.type,
    required this.label,
    required this.time,
    required this.dwell,
    this.location,
    this.name,
    this.address,
    TextEditingController? controller,
  }) : searchController = controller ?? TextEditingController();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stop &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          time == other.time;

  @override
  int get hashCode => label.hashCode ^ time.hashCode;
}

class PlaceResult {
  final String name;
  final String address;
  final LatLng location;
  final String placeId;
  PlaceResult({
    required this.name,
    required this.address,
    required this.location,
    required this.placeId,
  });
}

class DirectionsInfo {
  final List<LatLng> polyline;
  final int durationSec;
  final int distanceMeters;
  final List<dynamic> legsJson;
  DirectionsInfo({
    required this.polyline,
    required this.durationSec,
    required this.distanceMeters,
    required this.legsJson,
  });
}

class MapScreen extends StatefulWidget {
  final String? startAddress;
  final String? endAddress;
  final LatLng? startCoord;
  final LatLng? endCoord;
  // If you need departureTime, add it here:
  // final TimeOfDay? departureTime;

  MapScreen({
    this.startAddress,
    this.endAddress,
    this.startCoord,
    this.endCoord,
    // this.departureTime,
  }) : assert(
         (startAddress != null || startCoord != null) &&
             (endAddress != null || endCoord != null),
       );

  static String get _apiKey {
    final key = dotenv.env['GOOGLE_API_KEY'];
    if (key == null || key.isEmpty) {
      print('Error: GOOGLE_API_KEY not found in .env');
      return '';
    }
    return key;
  }

  static final Map<String, LatLng> _geocodeCache = {};
  static final Map<String, DirectionsInfo> _directionsCache = {};
  static final Map<String, List<PlaceResult>> _placesCache = {};

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _start;
  LatLng? _end;
  late DateTime _oldDepartureTime;
  DateTime _departureTime = DateTime.now();
  List<Stop> _stops = [];
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _routeLoaded = false;
  int _travelTimeSec = 0;
  int _distanceMeters = 0;
  Stop? _activeSearchStop;
  List<PlaceResult> _searchResults = [];
  Timer? _debounceTimer;
  DirectionsInfo? _lastDirections;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    DateTime today5am = DateTime(now.year, now.month, now.day, 5, 0);
    if (now.isAfter(today5am)) {
      _departureTime = today5am.add(Duration(days: 1));
    } else {
      _departureTime = today5am;
    }
    _oldDepartureTime = _departureTime;
    _initializeRoute();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (var stop in _stops) {
      stop.searchController.dispose();
    }
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeRoute() async {
    if (widget.startCoord != null) {
      _start = widget.startCoord;
    } else if (widget.startAddress != null) {
      _start = await _geocodeAddress(widget.startAddress!);
    }
    if (widget.endCoord != null) {
      _end = widget.endCoord;
    } else if (widget.endAddress != null) {
      _end = await _geocodeAddress(widget.endAddress!);
    }
    if (_start == null || _end == null) {
      if (mounted) setState(() => _routeLoaded = true);
      return;
    }

    DirectionsInfo? dir = await _fetchDirections(_start!, _end!, waypoints: []);
    if (dir != null) {
      _lastDirections = dir;
      _travelTimeSec = dir.durationSec;
      _distanceMeters = dir.distanceMeters;
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: dir.polyline,
          ),
        };
        _markers = {
          Marker(
            markerId: MarkerId('start'),
            position: _start!,
            infoWindow: InfoWindow(title: 'Start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: MarkerId('end'),
            position: _end!,
            infoWindow: InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
      });
    }

    if (mounted) {
      setState(() => _routeLoaded = true);
      if (_mapController != null) {
        Future.delayed(Duration(milliseconds: 100), () => _fitMapToRoute());
      }
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    if (MapScreen._geocodeCache.containsKey(address)) {
      return MapScreen._geocodeCache[address];
    }
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': address,
      'key': MapScreen._apiKey,
    });
    final data = await _getJsonWithRetry(url.toString());
    if (data != null &&
        data['status'] == 'OK' &&
        (data['results'] as List).isNotEmpty) {
      final loc = data['results'][0]['geometry']['location'];
      final latlng = LatLng(loc['lat'], loc['lng']);
      MapScreen._geocodeCache[address] = latlng;
      return latlng;
    }
    return null;
  }

  Future<DirectionsInfo?> _fetchDirections(
    LatLng origin,
    LatLng destination, {
    required List<LatLng> waypoints,
  }) async {
    if (MapScreen._apiKey.isEmpty) return null;

    String key =
        '${origin.latitude},${origin.longitude}->' +
        (waypoints.isNotEmpty
            ? waypoints.map((w) => '${w.latitude},${w.longitude}').join('|') +
                '->'
            : '') +
        '${destination.latitude},${destination.longitude}';

    if (MapScreen._directionsCache.containsKey(key)) {
      return MapScreen._directionsCache[key];
    }

    final params = {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': MapScreen._apiKey,
      'mode': 'driving',
      if (waypoints.isNotEmpty)
        'waypoints': waypoints
            .map((w) => '${w.latitude},${w.longitude}')
            .join('|'),
    };
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      params,
    );
    final data = await _getJsonWithRetry(url.toString());

    if (data != null &&
        data['status'] == 'OK' &&
        (data['routes'] as List).isNotEmpty) {
      final route = data['routes'][0];
      final polyStr = route['overview_polyline']['points'] as String;
      final polyPoints = _decodePolyline(polyStr);

      int totalDur = 0, totalDist = 0;
      final legs = route['legs'] as List<dynamic>;
      for (var leg in legs) {
        totalDur += leg['duration']['value'] as int;
        totalDist += leg['distance']['value'] as int;
      }

      final info = DirectionsInfo(
        polyline: polyPoints,
        durationSec: totalDur,
        distanceMeters: totalDist,
        legsJson: legs,
      );
      MapScreen._directionsCache[key] = info;
      return info;
    }
    return null;
  }

  Future<List<PlaceResult>> _searchPlaces(String query, LatLng location) async {
    if (MapScreen._apiKey.isEmpty) return [];
    final cacheKey = '$query|${location.latitude},${location.longitude}';
    if (MapScreen._placesCache.containsKey(cacheKey)) {
      return MapScreen._placesCache[cacheKey]!;
    }
    final params = {
      'query': query,
      'location': '${location.latitude},${location.longitude}',
      'radius': '50000',
      'key': MapScreen._apiKey,
    };
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      params,
    );
    final data = await _getJsonWithRetry(url.toString());
    final results = <PlaceResult>[];
    if (data != null && data['status'] == 'OK') {
      for (var r in data['results'] as List<dynamic>) {
        final geom = r['geometry']?['location'];
        if (geom == null) continue;
        results.add(
          PlaceResult(
            name: r['name'] as String? ?? 'Unknown Place',
            address: r['formatted_address'] as String? ?? 'Unknown Address',
            location: LatLng(geom['lat'], geom['lng']),
            placeId: r['place_id'] as String? ?? '',
          ),
        );
      }
    }
    MapScreen._placesCache[cacheKey] = results;
    return results;
  }

  Future<Map<String, dynamic>?> _getJsonWithRetry(String url) async {
    const maxRetries = 3, baseDelayMs = 500;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        }
        if ((response.statusCode == 429 || response.statusCode >= 500) &&
            attempt < maxRetries) {
          await Future.delayed(
            Duration(
              milliseconds: baseDelayMs * math.pow(2, attempt - 1).toInt(),
            ),
          );
          continue;
        }
        break;
      } catch (_) {
        if (attempt < maxRetries) {
          await Future.delayed(
            Duration(
              milliseconds: baseDelayMs * math.pow(2, attempt - 1).toInt(),
            ),
          );
          continue;
        }
        break;
      }
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLng _getCoordinateAtOffset(int offsetSec) {
    if (_lastDirections == null || _start == null || _end == null) {
      return _start ?? LatLng(0, 0);
    }
    final legs = _lastDirections!.legsJson;
    if (legs.isEmpty) return _start!;
    var remaining = offsetSec;
    final stops = _stopsWithLocation();
    int legIndex = 0, stopIndex = 0;
    while (legIndex < legs.length) {
      final leg = legs[legIndex] as Map<String, dynamic>;
      final legDur = leg['duration']['value'] as int;
      if (remaining < legDur) {
        var into = remaining, cum = 0;
        for (var step in leg['steps'] as List<dynamic>) {
          final sd = step['duration']['value'] as int;
          if (into < cum + sd) {
            final poly = _decodePolyline(step['polyline']['points'] as String);
            if (poly.length < 2) {
              final loc = step['end_location'];
              return LatLng(loc['lat'], loc['lng']);
            }
            final frac = (into - cum) / sd;
            final idx = (frac * (poly.length - 1)).clamp(
              0.0,
              poly.length - 1.0,
            );
            final p1 = poly[idx.floor()], p2 = poly[idx.ceil()];
            return LatLng(
              p1.latitude + (p2.latitude - p1.latitude) * (idx - idx.floor()),
              p1.longitude +
                  (p2.longitude - p1.longitude) * (idx - idx.floor()),
            );
          }
          cum += sd;
        }
        final endLoc = leg['end_location'];
        return LatLng(endLoc['lat'], endLoc['lng']);
      }
      remaining -= legDur;
      if (stopIndex < stops.length) {
        final d = stops[stopIndex].dwell.inSeconds;
        if (remaining < d) return stops[stopIndex].location!;
        remaining -= d;
        stopIndex++;
      }
      legIndex++;
    }
    return _end!;
  }

  List<Stop> _stopsWithLocation() =>
      _stops.where((s) => s.location != null).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  void _addMealStop(StopType type) {
    final label =
        {
          StopType.breakfast: 'Breakfast',
          StopType.lunch: 'Lunch',
          StopType.dinner: 'Dinner',
        }[type]!;
    if (_stops.any((s) => s.type == type)) {
      setState(() {
        _activeSearchStop = _stops.firstWhere((s) => s.type == type);
        _searchResults.clear();
      });
      return;
    }
    final offsets = {
      StopType.breakfast: Duration(hours: 3),
      StopType.lunch: Duration(hours: 6),
      StopType.dinner: Duration(hours: 12),
    };
    final newStop = Stop(
      type: type,
      label: label,
      time: _departureTime.add(offsets[type]!),
      dwell: Duration(minutes: 30),
    );
    setState(() {
      _stops.add(newStop);
      _stops.sort((a, b) => a.time.compareTo(b.time));
      _activeSearchStop = newStop;
      _searchResults.clear();
    });
  }

  void _addCustomStop(String customLabel) {
    if (customLabel.trim().isEmpty) return;
    final newStop = Stop(
      type: StopType.custom,
      label: customLabel.trim(),
      time: _departureTime.add(Duration(hours: 2)),
      dwell: Duration(minutes: 15),
    );
    setState(() {
      _stops.add(newStop);
      _stops.sort((a, b) => a.time.compareTo(b.time));
      _activeSearchStop = newStop;
      _searchResults.clear();
    });
  }

  void _removeStop(Stop stop) {
    setState(() {
      _stops.remove(stop);
      if (_activeSearchStop == stop) {
        _activeSearchStop = null;
        _searchResults.clear();
      }
    });
    if (stop.location != null) _updateRoute();
  }

  Future<void> _updateRoute() async {
    if (_start == null || _end == null) return;
    if (MapScreen._apiKey.isEmpty) return;
    final stopsWithLoc = _stopsWithLocation();
    final waypoints = stopsWithLoc.map((s) => s.location!).toList();
    final dir = await _fetchDirections(_start!, _end!, waypoints: waypoints);
    if (dir != null) {
      setState(() {
        _lastDirections = dir;
        _travelTimeSec = dir.durationSec;
        _distanceMeters = dir.distanceMeters;
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: dir.polyline,
          ),
        };
        _markers = {
          Marker(
            markerId: MarkerId('start'),
            position: _start!,
            infoWindow: InfoWindow(title: 'Start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: MarkerId('end'),
            position: _end!,
            infoWindow: InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
          ...stopsWithLoc.map((s) {
            final hue =
                s.type == StopType.custom
                    ? BitmapDescriptor.hueAzure
                    : BitmapDescriptor.hueViolet;
            final markerId = MarkerId(
              '${s.label}-${s.time.toIso8601String()}-${s.location!.latitude},${s.location!.longitude}',
            );
            return Marker(
              markerId: markerId,
              position: s.location!,
              infoWindow: InfoWindow(
                title: s.label,
                snippet: s.name ?? s.address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            );
          }),
        };
      });
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null || (_markers.isEmpty && _polylines.isEmpty)) {
      if (_start != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_start!, 12));
      }
      return;
    }
    LatLngBounds? bounds;
    if (_polylines.isNotEmpty) {
      final pts = _polylines.first.points;
      if (pts.isNotEmpty) {
        double minLat = pts.first.latitude,
            minLng = pts.first.longitude,
            maxLat = pts.first.latitude,
            maxLng = pts.first.longitude;
        for (var p in pts) {
          minLat = math.min(minLat, p.latitude);
          minLng = math.min(minLng, p.longitude);
          maxLat = math.max(maxLat, p.latitude);
          maxLng = math.max(maxLng, p.longitude);
        }
        bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
      }
    }
    if (bounds == null && _markers.isNotEmpty) {
      double minLat = 90, minLng = 180, maxLat = -90, maxLng = -180;
      bool has = false;
      for (var m in _markers) {
        minLat = math.min(minLat, m.position.latitude);
        minLng = math.min(minLng, m.position.longitude);
        maxLat = math.max(maxLat, m.position.latitude);
        maxLng = math.max(maxLng, m.position.longitude);
        has = true;
      }
      if (has) {
        bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
      }
    }
    if (bounds != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else if (_start != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_start!, 12));
    }
  }

  void _shiftStopTimes(Duration delta) {
    setState(() {
      for (var s in _stops) s.time = s.time.add(delta);
    });
  }

  String _formatDuration(int sec) {
    final d = Duration(seconds: sec);
    final h = d.inHours, m = d.inMinutes.remainder(60);
    return h > 0 ? '$h hr $m min' : '$m min';
  }

  String _formatDistance(int meters) {
    final miles = meters * 0.000621371;
    if (miles < 0.5) return '${(miles * 5280).round()} ft';
    return miles < 100
        ? '${miles.toStringAsFixed(1)} mi'
        : '${miles.round()} mi';
  }

  String _formatTime(DateTime t) {
    final h = t.hour, m = t.minute.toString().padLeft(2, '0');
    final pm = h >= 12, h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m ${pm ? 'PM' : 'AM'}';
  }

  Widget _buildStopTypeButton(String label, StopType type) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _addMealStop(type),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildStopListItem(Stop stop) {
    final isActive = _activeSearchStop == stop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(_getStopIcon(stop.type), color: _getStopColor(stop)),
          title: Text('${stop.label} (${_formatTime(stop.time)})'),
          subtitle: Text(stop.name ?? stop.address ?? 'Location not set'),
          trailing: Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.systemRed,
          ),
          onTap: () {
            setState(() {
              _activeSearchStop = isActive ? null : stop;
              _searchResults.clear();
              if (_activeSearchStop != null &&
                  (_activeSearchStop!.name != null ||
                      _activeSearchStop!.address != null)) {
                _activeSearchStop!.searchController.text =
                    _activeSearchStop!.name ?? _activeSearchStop!.address!;
              } else if (_activeSearchStop != null) {
                _activeSearchStop!.searchController.clear();
              }
            });
          },
        ),

        // *** SEARCH FIELD & RESULTS ***
        if (isActive)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: stop.searchController,
                  placeholder: 'Search for a place…',
                  prefix: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(CupertinoIcons.search),
                  ),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  onChanged: (value) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 400),
                      () async {
                        if (value.isNotEmpty && _activeSearchStop == stop) {
                          final loc =
                              stop.location ??
                              _getCoordinateAtOffset(_travelTimeSec ~/ 2);
                          final results = await _searchPlaces(value, loc);
                          if (_activeSearchStop == stop && mounted) {
                            setState(() => _searchResults = results);
                          }
                        } else {
                          if (_activeSearchStop == stop && mounted) {
                            setState(() => _searchResults.clear());
                          }
                        }
                      },
                    );
                  },
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) {
                        final res = _searchResults[i];
                        return CupertinoListTile(
                          title: Text(res.name),
                          subtitle: Text(res.address),
                          onTap: () {
                            setState(() {
                              stop.location = res.location;
                              stop.name = res.name;
                              stop.address = res.address;
                              stop.searchController.text = res.name;
                              _activeSearchStop = null;
                              _searchResults.clear();
                            });
                            _updateRoute();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        Divider(height: 1),
      ],
    );
  }

  IconData _getStopIcon(StopType type) {
    switch (type) {
      case StopType.breakfast:
        return CupertinoIcons.sun_dust_fill;
      case StopType.lunch:
        return CupertinoIcons.sun_max_fill;
      case StopType.dinner:
        return CupertinoIcons.moon_fill;
      case StopType.custom:
        return CupertinoIcons.location_solid;
    }
  }

  Color _getStopColor(Stop stop) {
    if (stop.location == null) return CupertinoColors.systemGrey;
    switch (stop.type) {
      case StopType.breakfast:
        return CupertinoColors.systemOrange;
      case StopType.lunch:
        return CupertinoColors.systemYellow;
      case StopType.dinner:
        return CupertinoColors.systemPurple;
      case StopType.custom:
        return CupertinoColors.activeBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTravelSec =
        _travelTimeSec +
        _stops.fold<int>(0, (sum, s) => sum + s.dwell.inSeconds);
    final arrival = _departureTime.add(Duration(seconds: totalTravelSec));
    final isNextDay =
        arrival.day != _departureTime.day || arrival.isBefore(_departureTime);
    final arrivalStr = '${_formatTime(arrival)}${isNextDay ? ' (+1 day)' : ''}';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Route Map'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.maybePop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.add_circled),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder:
                  (ctx) => CupertinoActionSheet(
                    title: Text('Add Stop Type'),
                    actions: [
                      CupertinoActionSheetAction(
                        child: Text('Breakfast Stop'),
                        onPressed: () {
                          _addMealStop(StopType.breakfast);
                          Navigator.pop(ctx);
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text('Lunch Stop'),
                        onPressed: () {
                          _addMealStop(StopType.lunch);
                          Navigator.pop(ctx);
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text('Dinner Stop'),
                        onPressed: () {
                          _addMealStop(StopType.dinner);
                          Navigator.pop(ctx);
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text('Custom Stop'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final labelCtrl = TextEditingController();
                          await showCupertinoDialog(
                            context: context,
                            builder:
                                (ctx2) => CupertinoAlertDialog(
                                  title: Text('Add Custom Stop'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 8),
                                      CupertinoTextField(
                                        controller: labelCtrl,
                                        placeholder:
                                            'Stop label (e.g. Gas, Scenic)',
                                        autofocus: true,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text('Cancel'),
                                      onPressed: () => Navigator.pop(ctx2),
                                    ),
                                    CupertinoDialogAction(
                                      child: Text('Add'),
                                      onPressed: () {
                                        final lbl = labelCtrl.text.trim();
                                        if (lbl.isNotEmpty) _addCustomStop(lbl);
                                        Navigator.pop(ctx2);
                                      },
                                    ),
                                  ],
                                ),
                          );
                          labelCtrl.dispose();
                        },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _start ?? LatLng(0, 0),
                zoom: _start != null ? 12 : 2,
              ),
              onMapCreated: (c) {
                _mapController = c;
                if (_routeLoaded) {
                  Future.delayed(
                    Duration(milliseconds: 100),
                    () => _fitMapToRoute(),
                  );
                }
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.2,
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              expand: true,
              builder:
                  (ctx, sc) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: ListView(
                      controller: sc,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          'Departure: ${_formatTime(_departureTime)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        CupertinoSlider(
                          min: 0,
                          max: (24 * 4 - 1).toDouble(),
                          divisions: 24 * 4 - 1,
                          value: (_departureTime.hour * 4 +
                                  (_departureTime.minute / 15))
                              .clamp(0.0, (24 * 4 - 1).toDouble()),
                          onChanged: (v) {
                            final steps = v.round();
                            final h = (steps * 15) ~/ 60;
                            final m = (steps * 15) % 60;
                            setState(() {
                              _departureTime = DateTime(
                                _departureTime.year,
                                _departureTime.month,
                                _departureTime.day,
                                h % 24,
                                m,
                              );
                            });
                          },
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Planned Stops:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStopTypeButton(
                              'Breakfast',
                              StopType.breakfast,
                            ),
                            SizedBox(width: 8),
                            _buildStopTypeButton('Lunch', StopType.lunch),
                            SizedBox(width: 8),
                            _buildStopTypeButton('Dinner', StopType.dinner),
                          ],
                        ),
                        SizedBox(height: 8),
                        // ==================== STOP LIST ====================
                        ..._stops.map(
                          (stop) => Dismissible(
                            key: ValueKey(stop),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeStop(stop),
                            background: Container(
                              color: CupertinoColors.systemRed,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(
                                CupertinoIcons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            child: _buildStopListItem(stop),
                          ),
                        ),
                        // =================== SUMMARY ROW ===================
                        Container(
                          margin: EdgeInsets.only(top: 8, bottom: 4),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: CupertinoColors.separator,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.clock,
                                    size: 18,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Travel: ${_formatDuration(_travelTimeSec)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.placemark,
                                    size: 18,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Distance: ${_formatDistance(_distanceMeters)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_down_circle,
                                    size: 18,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Arrival: $arrivalStr',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ], // ListView children
                    ), // ListView
                  ), // Container
            ), // DraggableScrollableSheet
          ], // Stack children
        ), // Stack
      ), // SafeArea
    ); // CupertinoPageScaffold
  } // build
} // _MapScreenState
