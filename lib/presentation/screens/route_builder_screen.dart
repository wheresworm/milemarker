import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart' as app_route;
import '../controllers/theme_controller.dart';
import '../widgets/animated_logo.dart';
import '../widgets/place_search_bar.dart';
import '../widgets/route_map.dart';
import '../widgets/route_stats_card.dart';
import '../widgets/stop_list.dart';
import '../widgets/route_actions.dart';
import '../widgets/meal_stop_selector.dart';
import '../../core/models/place.dart';

class RouteBuilderScreen extends StatefulWidget {
  const RouteBuilderScreen({super.key});

  @override
  State<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends State<RouteBuilderScreen>
    with TickerProviderStateMixin {
  Place? _origin;
  Place? _destination;

  late AnimationController _contentAnimationController;
  late AnimationController _bottomSheetController;
  late DraggableScrollableController _draggableController;

  @override
  void initState() {
    super.initState();
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _draggableController = DraggableScrollableController();

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    _bottomSheetController.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  void _handleRouteCreation() {
    if (_origin != null && _destination != null) {
      final routeController = context.read<app_route.RouteController>();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AnimatedLogo(size: 100),
        ),
      );

      // Build route
      routeController
          .buildRoute(
        origin: _origin!.latLng,
        destination: _destination!.latLng,
        originName: _origin!.name,
        destinationName: _destination!.name,
      )
          .then((_) {
        Navigator.pop(context); // Dismiss loading
        if (routeController.currentRoute != null) {
          // Navigate back to map
          Navigator.pop(context, routeController.currentRoute);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final routeController = context.watch<app_route.RouteController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plan Your Route',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Stack(
        children: [
          // Main content
          AnimatedBuilder(
            animation: _contentAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  50 * (1 - _contentAnimationController.value),
                ),
                child: Opacity(
                  opacity: _contentAnimationController.value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // Search inputs
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      PlaceSearchBar(
                        hintText: 'Starting point',
                        prefix: const Icon(Icons.trip_origin),
                        onPlaceSelected: (place) {
                          setState(() {
                            _origin = place;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      PlaceSearchBar(
                        hintText: 'Destination',
                        prefix: const Icon(Icons.location_on),
                        onPlaceSelected: (place) {
                          setState(() {
                            _destination = place;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: RouteMap(
                    origin: _origin?.latLng,
                    destination: _destination?.latLng,
                    stops: routeController.currentRoute?.stops ?? [],
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RouteActions(
              isValid: _origin != null && _destination != null,
              onCreateRoute: _handleRouteCreation,
              bottomSheetController: _bottomSheetController,
            ),
          ),

          // Loading overlay
          if (routeController.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: AnimatedLogo(size: 100),
              ),
            ),
        ],
      ),
    );
  }
}
