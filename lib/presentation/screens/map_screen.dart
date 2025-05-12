import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/providers/location_provider.dart';
import '../../data/providers/route_provider.dart';
import '../../core/utils/logger.dart';
import '../widgets/location_input.dart';
import '../widgets/map_with_route.dart';
import '../widgets/bottom_sheet_content.dart';
import 'trip_summary_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final double _bottomSheetMinHeight = 0.2;
  final double _bottomSheetMaxHeight = 0.8;
  double _bottomSheetHeight = 0.2;
  bool _showAdvancedSettings = false;
  final TextEditingController _mpgController = TextEditingController(
    text: '25',
  );
  final TextEditingController _tankRangeController = TextEditingController(
    text: '350',
  );

  @override
  void initState() {
    super.initState();
    AppLogger.info('MapScreen: Initializing');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mpgController.dispose();
    _tankRangeController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapToMarkers();
  }

  void _fitMapToMarkers() {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    if (_mapController == null) {
      return;
    }
    if (routeProvider.startLocation == null ||
        routeProvider.destinationLocation == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        routeProvider.startLocation!.latitude <
                routeProvider.destinationLocation!.latitude
            ? routeProvider.startLocation!.latitude
            : routeProvider.destinationLocation!.latitude,
        routeProvider.startLocation!.longitude <
                routeProvider.destinationLocation!.longitude
            ? routeProvider.startLocation!.longitude
            : routeProvider.destinationLocation!.longitude,
      ),
      northeast: LatLng(
        routeProvider.startLocation!.latitude >
                routeProvider.destinationLocation!.latitude
            ? routeProvider.startLocation!.latitude
            : routeProvider.destinationLocation!.latitude,
        routeProvider.startLocation!.longitude >
                routeProvider.destinationLocation!.longitude
            ? routeProvider.startLocation!.longitude
            : routeProvider.destinationLocation!.longitude,
      ),
    );

    // Add padding for the bottom sheet
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        100.0, // Increased padding
      ),
    );
  }

  void _addCustomStop() {
    showDialog(
      context: context,
      builder: (context) {
        String label = '';

        return AlertDialog(
          title: const Text('Add Custom Stop'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Stop Label',
              hintText: 'e.g., Gas, Scenic View',
            ),
            onChanged: (value) => label = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (label.isNotEmpty) {
                  final routeProvider = Provider.of<RouteProvider>(
                    context,
                    listen: false,
                  );
                  routeProvider.addCustomStop(label);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateRoute() async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    if (routeProvider.startLocation == null ||
        routeProvider.destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both start and destination locations'),
        ),
      );
      return;
    }

    final success = await routeProvider.calculateRoute();

    if (mounted) {
      if (success) {
        _fitMapToMarkers();
      } else if (routeProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${routeProvider.errorMessage!}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
          ),
        );
      }
    }
  }

  void _showTripSummary() {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    if (routeProvider.routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please calculate a route first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: _showTripSummary,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _addCustomStop,
          ),
        ],
      ),
      body: Consumer2<LocationProvider, RouteProvider>(
        builder: (context, locationProvider, routeProvider, child) {
          return Stack(
            children: [
              // Map taking the full screen
              MapWithRoute(
                routeData: routeProvider.routeData,
                startLocation: routeProvider.startLocation,
                destinationLocation: routeProvider.destinationLocation,
                stops: routeProvider.stops,
                onMapCreated: _onMapCreated,
              ),

              // Semi-transparent overlay at the top for inputs
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationInput(
                        label: 'Start Location',
                        initialValue: routeProvider.startAddress,
                        onLocationSelected: (address, lat, lng) {
                          routeProvider.setStartLocation(
                            address,
                            LatLng(lat, lng),
                          );
                        },
                      ),
                      LocationInput(
                        label: 'Destination',
                        initialValue: routeProvider.destinationAddress,
                        onLocationSelected: (address, lat, lng) {
                          routeProvider.setDestinationLocation(
                            address,
                            LatLng(lat, lng),
                          );
                        },
                      ),

                      // Row with Advanced Settings toggle and Plan Trip button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: Icon(
                              _showAdvancedSettings
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Advanced Settings',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showAdvancedSettings = !_showAdvancedSettings;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  routeProvider.isLoading
                                      ? null
                                      : _calculateRoute,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              child:
                                  routeProvider.isLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Plan My Trip',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),

                      // Advanced settings content
                      if (_showAdvancedSettings)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _mpgController,
                                  decoration: const InputDecoration(
                                    labelText: 'MPG',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _tankRangeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tank Range (mi)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * _bottomSheetHeight,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _bottomSheetHeight -=
                          details.delta.dy / MediaQuery.of(context).size.height;
                      _bottomSheetHeight = _bottomSheetHeight.clamp(
                        _bottomSheetMinHeight,
                        _bottomSheetMaxHeight,
                      );
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Handle for dragging with improved visibility
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        // Scrollable content with improved styling
                        Expanded(
                          child: BottomSheetContent(
                            onAddCustomStop: _addCustomStop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating action buttons for map controls
              Positioned(
                right: 16,
                bottom:
                    MediaQuery.of(context).size.height * _bottomSheetHeight +
                    16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'recenter',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      onPressed: _fitMapToMarkers,
                      child: const Icon(Icons.center_focus_strong),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'nearby',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      onPressed: () {
                        // TODO: Implement nearby search
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nearby search coming soon!'),
                          ),
                        );
                      },
                      child: const Icon(Icons.restaurant),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
