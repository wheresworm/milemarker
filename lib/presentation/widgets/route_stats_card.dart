import 'package:flutter/material.dart';
import '../../core/models/route.dart' as route_model;
import '../../core/models/stop.dart';
import '../../core/utils/formatters.dart';

class RouteStatsCard extends StatelessWidget {
  final route_model.Route route;

  const RouteStatsCard({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = route.stats;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Main stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    icon: Icons.straighten,
                    value: Formatters.formatDistance(stats?.totalDistance ?? 0),
                    label: 'Total Distance',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    context,
                    icon: Icons.timer,
                    value: Formatters.formatDuration(
                        stats?.totalDuration ?? Duration.zero),
                    label: 'Total Time',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    context,
                    icon: Icons.location_on,
                    value: (stats?.numberOfStops ?? 0).toString(),
                    label: 'Stops',
                    color: Colors.orange,
                  ),
                ],
              ),

              const Divider(height: 32),

              // Cost breakdown
              Text(
                'Estimated Costs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildCostRow(
                context,
                label: 'Fuel',
                amount: stats?.estimatedFuelCost ?? 0,
                icon: Icons.local_gas_station,
              ),
              const SizedBox(height: 8),
              _buildCostRow(
                context,
                label: 'Tolls',
                amount: stats?.estimatedTolls ?? 0,
                icon: Icons.toll,
              ),
              const SizedBox(height: 12),
              _buildCostRow(
                context,
                label: 'Total',
                amount: (stats?.estimatedFuelCost ?? 0) +
                    (stats?.estimatedTolls ?? 0),
                icon: Icons.attach_money,
                isTotal: true,
              ),

              if (stats?.mealStops.isNotEmpty ?? false) ...[
                const Divider(height: 32),
                Text(
                  'Meal Stops',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...stats!.mealStops.entries.map(
                  (entry) => _buildMealRow(context, entry.key, entry.value),
                ),
              ],

              if (stats?.statesTraversed.isNotEmpty ?? false) ...[
                const Divider(height: 32),
                Text(
                  'States Traversed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...stats!.statesTraversed.map(
                  (state) => _buildStateRow(context, state),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(
    BuildContext context, {
    required String label,
    required double amount,
    required IconData icon,
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              isTotal ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMealRow(BuildContext context, MealType type, int count) {
    IconData icon;
    switch (type) {
      case MealType.breakfast:
        icon = Icons.breakfast_dining;
        break;
      case MealType.lunch:
        icon = Icons.lunch_dining;
        break;
      case MealType.dinner:
        icon = Icons.dinner_dining;
        break;
      case MealType.snack:
        icon = Icons.local_cafe;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Text(type.toString().split('.').last.capitalize()),
          const Spacer(),
          Text('$count stop${count > 1 ? 's' : ''}'),
        ],
      ),
    );
  }

  Widget _buildStateRow(BuildContext context, route_model.StateInfo state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.abbreviation,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${state.milesInState.toStringAsFixed(0)} miles • '
                  '${Formatters.formatDuration(state.timeInState)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${state.speedLimit} mph',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
