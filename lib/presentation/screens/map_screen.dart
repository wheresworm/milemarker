import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/trip.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import '../widgets/animated_tracking_button.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../widgets/speed_display_overlay.dart';

class MapScreen extends StatefulWidget {
  final bool isTracking;
  final Trip? currentTrip;
  final LatLng? currentLocation;
  final VoidCallback onToggleTracking;
  final VoidCallback onPlanRoute;
  final AnimationController fabAnimationController;
  final AnimationController bottomSheetController;

  const MapScreen({
    super.key,
    required this.isTracking,
    required this.currentTrip,
    required this.currentLocation,
    required this.onToggleTracking,
    required this.onPlanRoute,
    required this.fabAnimationController,
    required this.bottomSheetController,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  final LatLng _defaultLocation = const LatLng(37.7749, -122.4194);
  double _currentZoom = 15.0;

  late AnimationController _mapLoadingController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mapLoadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mapLoadingController,
      curve: Curves.easeInOut,
    );
    _mapLoadingController.forward();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentTrip != null &&
        widget.currentTrip != oldWidget.currentTrip) {
      _updateRoute();
    }

    if (widget.currentLocation != oldWidget.currentLocation) {
      _updateCurrentLocationMarker();
      if (widget.isTracking) {
        _animateCameraToLocation(widget.currentLocation!);
      }
    }
  }

  void _updateRoute() {
    if (widget.currentTrip == null) return;

    final List<LatLng> points =
        widget.currentTrip!.route.map((point) => point.toLatLng()).toList();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('trip_route'),
          points: points,
          color: AppColors.primary,
          width: 5,
          patterns: [],
          geodesic: true,
        ),
      };
    });
  }

  void _updateCurrentLocationMarker() {
    if (widget.currentLocation == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: widget.currentLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
        ),
      };
    });
  }

  void _animateCameraToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, _currentZoom),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();

    if (widget.currentLocation != null) {
      _animateCameraToLocation(widget.currentLocation!);
    }
  }

  void _setMapStyle() async {
    final String style = await rootBundle.loadString('assets/map_style.json');
    _mapController?.setMapStyle(style);
  }

  @override
  void dispose() {
    _mapLoadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FadeTransition(
            opacity: _fadeAnimation,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation ?? _defaultLocation,
                zoom: _currentZoom,
              ),
              onMapCreated: _onMapCreated,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              polylines: _polylines,
              markers: _markers,
              onCameraMove: (position) {
                _currentZoom = position.zoom;
              },
              mapType: MapType.normal,
              padding: EdgeInsets.only(bottom: bottomPadding + 80),
            ),
          ),

          // Speed/Stats Overlay
          if (widget.isTracking && widget.currentTrip != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: SpeedDisplayOverlay(
                speed: widget.currentTrip!.averageSpeed,
                distance: widget.currentTrip!.distance,
                duration: widget.currentTrip!.duration,
              ),
            ),

          // Tracking FAB
          Positioned(
            bottom: bottomPadding + 100,
            right: 16,
            child: AnimatedTrackingButton(
              isTracking: widget.isTracking,
              onPressed: widget.onToggleTracking,
              animationController: widget.fabAnimationController,
            ),
          ),

          // Plan Route FAB
          Positioned(
            bottom: bottomPadding + 180,
            right: 16,
            child: FloatingActionButton(
              onPressed: widget.onPlanRoute,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add_location),
              heroTag: 'plan_route',
            ),
          ),

          // Center on location button
          Positioned(
            bottom: bottomPadding + 260,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                if (widget.currentLocation != null) {
                  _animateCameraToLocation(widget.currentLocation!);
                }
              },
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: theme.colorScheme.primary,
              ),
              heroTag: 'my_location',
            ),
          ),

          // Trip Bottom Sheet
          TripBottomSheet(
            isTracking: widget.isTracking,
            currentTrip: widget.currentTrip,
            animationController: widget.bottomSheetController,
            onExpand: () {
              // Handle expansion
            },
          ),
        ],
      ),
    );
  }
}
