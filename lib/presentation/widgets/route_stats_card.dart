// lib/presentation/widgets/route_stats_card.dart
import 'package:flutter/material.dart';
import '../../core/models/route_stats.dart';
import '../../core/models/stop.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/fuel_stop.dart';
import '../../core/models/place_stop.dart';

// Rest of the file continues...
class RouteStatsCard extends StatelessWidget {
  final RouteStats stats;
  final bool expanded;

  const RouteStatsCard({
    super.key,
    required this.stats,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!expanded) {
      return _buildCompactView(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Distance',
              '${stats.totalDistance.toStringAsFixed(1)} mi',
              Icons.straighten,
            ),
            _buildStatRow(
              context,
              'Duration',
              _formatDuration(stats.totalDuration),
              Icons.timer,
            ),
            _buildStatRow(
              context,
              'Average Speed',
              '${stats.averageSpeed.toStringAsFixed(1)} mph',
              Icons.speed,
            ),
            const Divider(height: 24),
            _buildCostEstimates(context),
            const Divider(height: 24),
            _buildStopBreakdown(context),
            if (stats.statesTraversed.isNotEmpty) ...[
              const Divider(height: 24),
              _buildStateBreakdown(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCompactStat(
              context,
              Icons.straighten,
              '${stats.totalDistance.toStringAsFixed(1)} mi',
            ),
            _buildCompactStat(
              context,
              Icons.timer,
              _formatDuration(stats.totalDuration),
            ),
            if (stats.estimatedFuelCost > 0)
              _buildCompactStat(
                context,
                Icons.local_gas_station,
                '\$${stats.estimatedFuelCost.toStringAsFixed(2)}',
              ),
            if (stats.estimatedTolls > 0)
              _buildCompactStat(
                context,
                Icons.toll,
                '\$${stats.estimatedTolls.toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, IconData icon, String value) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostEstimates(BuildContext context) {
    final theme = Theme.of(context);
    final totalCost = stats.estimatedFuelCost + stats.estimatedTolls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Costs',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (stats.estimatedFuelCost > 0)
          _buildCostRow(
            context,
            'Fuel',
            '\$${stats.estimatedFuelCost.toStringAsFixed(2)}',
          ),
        if (stats.estimatedTolls > 0)
          _buildCostRow(
            context,
            'Tolls',
            '\$${stats.estimatedTolls.toStringAsFixed(2)}',
          ),
        const Divider(height: 8),
        _buildCostRow(
          context,
          'Total',
          '\$${totalCost.toStringAsFixed(2)}',
          bold: true,
        ),
      ],
    );
  }

  Widget _buildCostRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.bold : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: textStyle),
          const Spacer(),
          Text(value, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildStopBreakdown(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stops',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...stats.stopTypeBreakdown.entries.map((entry) {
          return _buildStopTypeRow(
            context,
            entry.key,
            entry.value,
          );
        }).toList(),
        if (stats.mealStops.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Meal Stops:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ...stats.mealStops.map((stop) => _buildMealStopDetail(context, stop)),
        ],
      ],
    );
  }

  Widget _buildStopTypeRow(BuildContext context, Type type, int count) {
    final theme = Theme.of(context);
    String typeName = type.toString().split('.').last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getIconForType(type),
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(typeName),
          const Spacer(),
          Text('$count'),
        ],
      ),
    );
  }

  Widget _buildMealStopDetail(BuildContext context, Stop stop) {
    if (stop is! FoodStop) return const SizedBox();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4),
      child: Row(
        children: [
          Icon(
            _getMealIcon(stop.mealType),
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${stop.mealType.toString().split('.').last.capitalize()} at ${stop.name}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.breakfast_dining;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      // Removed MealType.snack case since it doesn't exist
    }
  }

  Widget _buildStateBreakdown(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'States Traversed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...stats.statesTraversed.map((state) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_city,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(state.stateName),
                const Spacer(),
                Text(
                  '${state.miles.toStringAsFixed(1)} mi',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getIconForType(Type type) {
    if (type == FoodStop) return Icons.restaurant;
    if (type == FuelStop) return Icons.local_gas_station;
    if (type == PlaceStop) return Icons.place;
    return Icons.stop_circle;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
