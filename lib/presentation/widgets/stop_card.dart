import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/stop.dart';
import '../../core/models/food_stop.dart';
import '../../core/models/fuel_stop.dart';
import '../../core/models/place_stop.dart';

class StopCard extends StatelessWidget {
  final Stop stop;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const StopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Drag handle
              Icon(
                Icons.drag_handle,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 16),

              // Stop icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStopColor(theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStopIcon(),
                  color: _getStopColor(theme),
                ),
              ),
              const SizedBox(width: 16),

              // Stop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStopSubtitle(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (stop.timeWindow != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(stop.timeWindow!.preferred),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onRemove!();
                  },
                  color: theme.colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStopIcon() {
    if (stop is FoodStop) {
      switch ((stop as FoodStop).mealType) {
        case MealType.breakfast:
          return Icons.breakfast_dining;
        case MealType.lunch:
          return Icons.lunch_dining;
        case MealType.dinner:
          return Icons.dinner_dining;
        case MealType.snack:
          return Icons.local_cafe;
      }
    } else if (stop is FuelStop) {
      return Icons.local_gas_station;
    } else if (isFirst) {
      return Icons.home;
    } else if (isLast) {
      return Icons.flag;
    }
    return Icons.location_on;
  }

  Color _getStopColor(ThemeData theme) {
    if (stop is FoodStop) {
      return Colors.orange;
    } else if (stop is FuelStop) {
      return Colors.blue;
    } else if (isFirst) {
      return Colors.green;
    } else if (isLast) {
      return Colors.red;
    }
    return theme.colorScheme.primary;
  }

  String _getStopSubtitle() {
    if (stop is FoodStop) {
      final foodStop = stop as FoodStop;
      if (foodStop.selectedRestaurant != null) {
        return foodStop.selectedRestaurant!.name;
      }
      return '${foodStop.mealType.toString().split('.').last} stop';
    } else if (stop is FuelStop) {
      final fuelStop = stop as FuelStop;
      return '${fuelStop.brand.toString().split('.').last} - \$${fuelStop.pricePerGallon.toStringAsFixed(2)}/gal';
    } else if (isFirst) {
      return 'Starting point';
    } else if (isLast) {
      return 'Destination';
    }
    return 'Stop ${index + 1}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
