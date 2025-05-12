import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../data/models/stop.dart';
import '../../data/models/route_data.dart';
import '../../core/utils/logger.dart';

class MapWithRoute extends StatefulWidget {
  final RouteData? routeData;
  final LatLng? startLocation;
  final LatLng? destinationLocation;
  final List<Stop> stops;
  final Function(GoogleMapController) onMapCreated;

  const MapWithRoute({
    super.key,
    this.routeData,
    this.startLocation,
    this.destinationLocation,
    required this.stops,
    required this.onMapCreated,
  });

  @override
  State<MapWithRoute> createState() => _MapWithRouteState();
}

class _MapWithRouteState extends State<MapWithRoute> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _updateMapData();
  }

  @override
  void didUpdateWidget(MapWithRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeData != widget.routeData ||
        oldWidget.startLocation != widget.startLocation ||
        oldWidget.destinationLocation != widget.destinationLocation ||
        oldWidget.stops != widget.stops) {
      _updateMapData();
    }
  }

  void _updateMapData() {
    _updateMarkers();
    _updatePolylines();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add start marker
    if (widget.startLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: widget.startLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
    }

    // Add destination marker
    if (widget.destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Add stop markers
    for (final stop in widget.stops) {
      if (stop.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId(stop.id),
            position: stop.location!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: stop.label,
              snippet: stop.placeName ?? _formatTime(stop.plannedTime),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updatePolylines() {
    final polylines = <Polyline>{};

    if (widget.routeData != null) {
      final polylinePoints = PolylinePoints();
      final points = polylinePoints.decodePolyline(widget.routeData!.polyline);

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points:
            points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
        width: 5,
      );

      polylines.add(polyline);
    }

    setState(() {
      _polylines = polylines;
    });

    // Fit the route bounds after polylines are updated
    if (_polylines.isNotEmpty) {
      // Small delay to ensure the map is ready
      Future.delayed(const Duration(milliseconds: 300), _fitPolylineToBounds);
    }
  }

  void _fitPolylineToBounds() {
    if (_polylines.isEmpty || _mapController == null) return;

    final points = _polylines.first.points;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add padding for the start and end markers
    double latPadding = (maxLat - minLat) * 0.2; // Increased padding
    double lngPadding = (maxLng - minLng) * 0.2;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Add padding to ensure the entire route is visible considering UI elements
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));

    AppLogger.info('MapWithRoute: Map bounds updated to fit route');
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        // Start with a more zoomed out view of the US
        target: const LatLng(39.8283, -98.5795), // Center of US
        zoom: 4.0,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated(controller);

        // If we have a route already, fit it to the bounds
        if (_polylines.isNotEmpty) {
          Future.delayed(
            const Duration(milliseconds: 500),
            _fitPolylineToBounds,
          );
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We'll add our own button
      compassEnabled: true,
      zoomControlsEnabled: false,
      padding: const EdgeInsets.only(
        top: 180,
        bottom: 200,
      ), // Adjust based on your UI
    );
  }

  // Helper to format time
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hourDisplay:$minute $period';
  }
}
