import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/stop.dart';
import '../../core/models/user_route.dart';

class RouteMap extends StatelessWidget {
  final UserRoute? route;
  final void Function(GoogleMapController) onMapCreated;
  final void Function(LatLng)? onMapTap;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final LatLng? initialPosition;

  const RouteMap({
    super.key,
    this.route,
    required this.onMapCreated,
    this.onMapTap,
    this.markers,
    this.polylines,
    this.initialPosition,
  });

  @override
  Widget build(BuildContext context) {
    final initialPos = initialPosition ??
        route?.stops.firstOrNull?.location ??
        const LatLng(37.7749, -122.4194); // Default to San Francisco

    return GoogleMap(
      onMapCreated: onMapCreated,
      onTap: onMapTap,
      initialCameraPosition: CameraPosition(
        target: initialPos,
        zoom: 12,
      ),
      markers: markers ?? _buildMarkersFromRoute(),
      polylines: polylines ?? _buildPolylinesFromRoute(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
      compassEnabled: true,
    );
  }

  Set<Marker> _buildMarkersFromRoute() {
    if (route == null) return {};

    return route!.stops.map((stop) {
      return Marker(
        markerId: MarkerId(stop.id),
        position: stop.location,
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: _getStopDescription(stop),
        ),
        icon: _getMarkerIcon(stop),
      );
    }).toSet();
  }

  Set<Polyline> _buildPolylinesFromRoute() {
    if (route == null || route!.polylinePoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: route!.polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  BitmapDescriptor _getMarkerIcon(Stop stop) {
    switch (stop.type) {
      case StopType.origin:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case StopType.destination:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case StopType.meal:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case StopType.fuel:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      case StopType.hotel:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  String _getStopDescription(Stop stop) {
    switch (stop.type) {
      case StopType.meal:
        return 'Meal stop';
      case StopType.fuel:
        return 'Fuel stop';
      case StopType.hotel:
        return 'Hotel';
      case StopType.rest:
        return 'Rest area';
      case StopType.scenic:
        return 'Scenic viewpoint';
      default:
        return '';
    }
  }
}
