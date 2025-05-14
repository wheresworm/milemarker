import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/route.dart' as route_model;
import '../../core/models/stop.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/fuel_stop.dart';
import '../../core/models/place_stop.dart';

class RouteMap extends StatefulWidget {
  final route_model.Route? route;
  final Function(LatLng) onMapTap;

  const RouteMap({
    super.key,
    required this.route,
    required this.onMapTap,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route) {
      _updateMap();
    }
  }

  void _updateMap() {
    if (widget.route == null) return;

    // Create markers for stops
    _markers = widget.route!.stops.map((stop) {
      IconData iconData;
      Color color;

      if (stop is FoodStop) {
        iconData = Icons.restaurant;
        color = Colors.orange;
      } else if (stop is FuelStop) {
        iconData = Icons.local_gas_station;
        color = Colors.blue;
      } else if (stop.order == 0) {
        iconData = Icons.home;
        color = Colors.green;
      } else if (stop.order == widget.route!.stops.length - 1) {
        iconData = Icons.flag;
        color = Colors.red;
      } else {
        iconData = Icons.location_on;
        color = Colors.purple;
      }

      return Marker(
        markerId: MarkerId(stop.id),
        position: stop.location,
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: _getStopSnippet(stop),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(color),
        ),
      );
    }).toSet();

    // Create polyline for route
    if (widget.route!.directions != null) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _decodePolyline(widget.route!.directions!.encodedPolyline),
          color: Colors.blue,
          width: 5,
          patterns: [],
          geodesic: true,
        ),
      };
    }

    // Fit camera to show entire route
    if (_mapController != null && widget.route!.directions != null) {
      final bounds = widget.route!.directions!.bounds;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: bounds.northeast,
            southwest: bounds.southwest,
          ),
          100, // padding
        ),
      );
    }
  }

  String _getStopSnippet(Stop stop) {
    if (stop is FoodStop) {
      return '${stop.mealType.toString().split('.').last} stop';
    } else if (stop is FuelStop) {
      return '\$${stop.pricePerGallon.toStringAsFixed(2)}/gal';
    } else if (stop.order == 0) {
      return 'Start point';
    } else if (stop.order == widget.route!.stops.length - 1) {
      return 'Destination';
    }
    return 'Stop ${stop.order}';
  }

  double _getMarkerHue(Color color) {
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.route?.origin ?? const LatLng(37.7749, -122.4194),
        zoom: 10,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMap();
      },
      markers: _markers,
      polylines: _polylines,
      onTap: widget.onMapTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
