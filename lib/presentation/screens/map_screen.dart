import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/models/stop.dart';
import '../controllers/route_controller.dart';
import '../widgets/place_search_bar.dart';
import '../widgets/route_map.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../../core/models/place.dart'; // Added this import

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late AnimationController _bottomSheetController;
  late AnimationController _fabAnimationController;
  late GoogleMapController _mapController;

  bool _isSearching = false;
  bool _isTracking = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _fabAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    // This would normally get the user's current location
    // For now, we'll use a default location
    setState(() {
      _currentLocation = const LatLng(37.7749, -122.4194); // San Francisco
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });
  }

  void _planRoute() {
    Navigator.pushNamed(context, '/route-builder');
  }

  void _onPlaceSelected(Place place) {
    final routeController = context.read<RouteController>();
    final stop = Stop(
      id: place.id,
      name: place.name,
      location: place.location, // Use place.location which is already a LatLng
      order: routeController.stops.length,
    );
    routeController.addStop(stop);
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeController = context.watch<RouteController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          RouteMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _loadMapStyle();
            },
            // Remove the undefined parameters and add the required ones
          ),

          // Search Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _isSearching
                ? PlaceSearchBar(
                    onPlaceSelected: _onPlaceSelected,
                    // Remove onClose parameter
                  )
                : Container(),
          ),

          // Bottom Sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: 0,
            left: 0,
            right: 0,
            child: TripBottomSheet(
              animationController: _bottomSheetController,
              isTracking: _isTracking,
              onExpand: () {
                // Handle expand action
              },
              route: routeController.currentRoute,
              onTripStart: () {
                // Start trip
              },
              onTripEnd: () {
                // End trip
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search FAB
          FloatingActionButton(
            heroTag: 'search',
            onPressed: _toggleSearch,
            child: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          const SizedBox(height: 16),
          // Plan Route FAB
          FloatingActionButton(
            heroTag: 'plan',
            onPressed: _planRoute,
            child: const Icon(Icons.add_road),
          ),
          const SizedBox(height: 16),
          // Tracking FAB
          FloatingActionButton(
            heroTag: 'track',
            onPressed: _toggleTracking,
            backgroundColor: _isTracking ? theme.colorScheme.primary : null,
            child: Icon(
              _isTracking ? Icons.stop : Icons.play_arrow,
              color: _isTracking ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMapStyle() async {
    final String style = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');
    _mapController.setMapStyle(style);
  }
}
