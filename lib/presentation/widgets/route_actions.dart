import 'package:flutter/material.dart';
import '../../core/models/route.dart' as route_model;

class RouteActions extends StatelessWidget {
  final route_model.Route? route;
  final VoidCallback onAddMealStop;
  final VoidCallback onAddFuelStop;
  final VoidCallback onOptimize;
  final VoidCallback onStartNavigation;

  const RouteActions({
    super.key,
    required this.route,
    required this.onAddMealStop,
    required this.onAddFuelStop,
    required this.onOptimize,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ActionChip(
            label: const Text('Add Meals'),
            avatar: const Icon(Icons.restaurant, size: 18),
            onPressed: route != null ? onAddMealStop : null,
            backgroundColor: Colors.orange.shade100,
          ),
          ActionChip(
            label: const Text('Add Fuel'),
            avatar: const Icon(Icons.local_gas_station, size: 18),
            onPressed: route != null ? onAddFuelStop : null,
            backgroundColor: Colors.blue.shade100,
          ),
          ActionChip(
            label: const Text('Optimize'),
            avatar: const Icon(Icons.route, size: 18),
            onPressed:
                route != null && route!.stops.length > 2 ? onOptimize : null,
            backgroundColor: Colors.green.shade100,
          ),
          FilledButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text('Start'),
            onPressed: route != null && route!.stops.length >= 2
                ? onStartNavigation
                : null,
          ),
        ],
      ),
    );
  }
}
