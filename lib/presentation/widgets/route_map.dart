// lib/presentation/widgets/route_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/stop.dart';
import '../../core/models/user_route.dart';

class RouteMap extends StatefulWidget {
  final UserRoute? route;
  final LatLng? currentLocation;
  final Function(GoogleMapController)? onMapCreated;
  final bool showTraffic;
  final bool showCurrentLocation;

  const RouteMap({
    super.key,
    this.route,
    this.currentLocation,
    this.onMapCreated,
    this.showTraffic = false,
    this.showCurrentLocation = true,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _buildMapElements();
  }

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route ||
        oldWidget.currentLocation != widget.currentLocation) {
      _buildMapElements();
    }
  }

  void _buildMapElements() {
    if (widget.route == null) return;

    final route = widget.route!;

    // Build markers
    final markers = <Marker>{};

    // Add stops as markers
    for (int i = 0; i < route.stops.length; i++) {
      final stop = route.stops[i];
      final isFirstOrLast = i == 0 || i == route.stops.length - 1;

      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: stop.location,
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: _getStopTypeString(stop.stopType),
          ),
          icon: _getMarkerIcon(stop.stopType, isFirstOrLast),
        ),
      );
    }

    // Add current location marker if available
    if (widget.currentLocation != null && widget.showCurrentLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: widget.currentLocation!,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Build polylines
    final polylines = <Polyline>{};
    if (route.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: route.polylinePoints,
          color: Theme.of(context).primaryColor,
          width: 5,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  BitmapDescriptor _getMarkerIcon(StopType type, bool isFirstOrLast) {
    if (isFirstOrLast) {
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
    }

    switch (type) {
      case StopType.food:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case StopType.fuel:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
      case StopType.rest:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case StopType.hotel:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      case StopType.scenic:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueCyan,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  String _getStopTypeString(StopType type) {
    switch (type) {
      case StopType.origin:
        return 'Start';
      case StopType.destination:
        return 'End';
      case StopType.food:
        return 'Meal Stop';
      case StopType.fuel:
        return 'Fuel Stop';
      case StopType.rest:
        return 'Rest Stop';
      case StopType.hotel:
        return 'Hotel';
      case StopType.scenic:
        return 'Scenic Point';
      case StopType.place:
        return 'Place';
      case StopType.custom:
        return 'Stop';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _getInitialCameraPosition(),
      onMapCreated: _onMapCreated,
      markers: _markers,
      polylines: _polylines,
      trafficEnabled: widget.showTraffic,
      myLocationEnabled: widget.showCurrentLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }

  CameraPosition _getInitialCameraPosition() {
    if (widget.currentLocation != null) {
      return CameraPosition(
        target: widget.currentLocation!,
        zoom: 14,
      );
    }

    if (widget.route != null && widget.route!.stops.isNotEmpty) {
      return CameraPosition(
        target: widget.route!.stops.first.location,
        zoom: 12,
      );
    }

    // Default to center of US
    return const CameraPosition(
      target: LatLng(39.8283, -98.5795),
      zoom: 4,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    widget.onMapCreated?.call(controller);

    // Fit bounds to show entire route
    if (widget.route != null && widget.route!.stops.isNotEmpty) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_mapController == null || widget.route == null) return;

    final bounds = _calculateBounds();
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds() {
    final points = <LatLng>[];

    if (widget.route != null) {
      points.addAll(widget.route!.stops.map((stop) => stop.location));
      points.addAll(widget.route!.polylinePoints);
    }

    if (widget.currentLocation != null) {
      points.add(widget.currentLocation!);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
