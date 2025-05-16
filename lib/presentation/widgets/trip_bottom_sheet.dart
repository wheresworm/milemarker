import 'package:flutter/material.dart';
import '../../core/models/trip.dart';
import '../../core/models/user_route.dart';

class TripBottomSheet extends StatefulWidget {
  final AnimationController animationController;
  final UserRoute? route;
  final Trip? currentTrip;
  final bool isTracking;
  final VoidCallback onExpand;
  final VoidCallback? onTripStart;
  final VoidCallback? onTripEnd;

  const TripBottomSheet({
    super.key,
    required this.animationController,
    this.route,
    this.currentTrip,
    required this.isTracking,
    required this.onExpand,
    this.onTripStart,
    this.onTripEnd,
  });

  @override
  State<TripBottomSheet> createState() => _TripBottomSheetState();
}

class _TripBottomSheetState extends State<TripBottomSheet> {
  double _sheetPosition = 0.1; // Start at 10% of screen height

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _sheetPosition -= details.delta.dy / size.height;
          _sheetPosition = _sheetPosition.clamp(0.1, 0.9);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: size.height * _sheetPosition,
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.route != null) ...[
                      _buildRouteInfo(theme),
                      const SizedBox(height: 16),
                      _buildTripControls(theme),
                    ] else
                      _buildEmptyState(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(ThemeData theme) {
    final route = widget.route!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.name,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(route.totalDuration),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.straighten,
                    size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${route.totalDistance.toStringAsFixed(1)} mi',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${route.stops.length} stops',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripControls(ThemeData theme) {
    if (widget.currentTrip != null && widget.isTracking) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: widget.onTripEnd,
            icon: const Icon(Icons.stop),
            label: const Text('End Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.currentTrip!.startTime != null
                ? 'Trip started ${_formatDateTime(widget.currentTrip!.startTime!)}'
                : 'Trip started',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: widget.onTripStart,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Trip'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: theme.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No route selected',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Plan a route to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
