// lib/presentation/screens/route_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart';
import '../widgets/place_search_bar.dart';
import 'map_screen.dart';

class RouteBuilderScreen extends StatefulWidget {
  const RouteBuilderScreen({super.key});

  @override
  State<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends State<RouteBuilderScreen> {
  LatLng? _startLocation;
  LatLng? _endLocation;
  String? _startName;
  String? _endName;

  void _onPlanRoute() async {
    if (_startLocation != null && _endLocation != null) {
      final routeController = context.read<RouteController>();

      await routeController.buildRoute(
        origin: _startLocation!,
        destination: _endLocation!,
        originName: _startName ?? 'Start',
        destinationName: _endName ?? 'End',
      );

      if (mounted && routeController.currentTrip != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MapScreen(
              currentTrip: routeController.currentTrip,
              isTracking: false,
              currentLocation: null,
              onToggleTracking: () {},
              bottomSheetController: DraggableScrollableController(),
              fabAnimationController: AnimationController(
                vsync: Navigator.of(context),
                duration: const Duration(milliseconds: 200),
              ),
              onPlanRoute: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeController = context.watch<RouteController>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Plan Your Route'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Route Input Container
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Start Location Input
                PlaceSearchBar(
                  hintText: 'Enter start location',
                  onLocationSelected: (location, name) {
                    setState(() {
                      _startLocation = location;
                      _startName = name;
                    });
                  },
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 12),

                // End Location Input
                PlaceSearchBar(
                  hintText: 'Enter destination',
                  isDestination: true,
                  onLocationSelected: (location, name) {
                    setState(() {
                      _endLocation = location;
                      _endName = name;
                    });
                  },
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 16),

                // Plan Route Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_startLocation != null && _endLocation != null)
                        ? _onPlanRoute
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: routeController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Plan Route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Recent Routes Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Recent Routes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'No recent routes',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
