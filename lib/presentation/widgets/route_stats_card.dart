import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/trip.dart';
import '../../core/utils/formatters.dart';
import '../controllers/tracking_controller.dart';

class RouteStatsCard extends StatelessWidget {
  final Trip trip;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onEndTrip;

  const RouteStatsCard({
    super.key,
    required this.trip,
    required this.isExpanded,
    required this.onExpand,
    this.onStartNavigation,
    this.onEndTrip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingController = context.watch<TrackingController>();
    final isTracking = trackingController.currentTripId == trip.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded ? MediaQuery.of(context).size.height * 0.4 : 120,
      child: Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isExpanded
                ? _buildExpandedContent(context)
                : _buildCollapsedContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _buildStatColumn(
          context,
          Icons.route,
          Formatters.formatDistance(trip.totalDistance ?? 0),
          'Distance',
        ),
        const Spacer(),
        _buildStatColumn(
          context,
          Icons.access_time,
          Formatters.formatDuration(trip.totalDuration ?? Duration.zero),
          'Duration',
        ),
        const Spacer(),
        _buildStatColumn(
          context,
          Icons.place,
          '${trip.stops?.length ?? 0}',
          'Stops',
        ),
        const SizedBox(width: 16),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Text(
              trip.title,
              style: theme.textTheme.headlineMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onExpand,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildStatsGrid(context),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          context,
          Icons.route,
          Formatters.formatDistance(trip.totalDistance ?? 0),
          'Total Distance',
          Colors.blue,
        ),
        _buildStatCard(
          context,
          Icons.access_time,
          Formatters.formatDuration(trip.totalDuration ?? Duration.zero),
          'Duration',
          Colors.green,
        ),
        _buildStatCard(
          context,
          Icons.place,
          '${trip.stops?.length ?? 0}',
          'Stops',
          Colors.orange,
        ),
        _buildStatCard(
          context,
          Icons.speed,
          '${_calculateAverageSpeed().toStringAsFixed(0)} mph',
          'Avg Speed',
          Colors.purple,
        ),
        _buildStatCard(
          context,
          Icons.schedule,
          _getEstimatedArrival(),
          'ETA',
          Colors.red,
        ),
        _buildStatCard(
          context,
          Icons.trending_up,
          '+${_getElevationGain()}ft',
          'Elevation',
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final trackingController = context.watch<TrackingController>();
    final isTracking = trackingController.currentTripId == trip.id;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (trip.status == TripStatus.active && !isTracking)
          ElevatedButton.icon(
            onPressed: onStartNavigation,
            icon: const Icon(Icons.navigation),
            label: const Text('Start Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        else if (isTracking)
          ElevatedButton.icon(
            onPressed: onEndTrip,
            icon: const Icon(Icons.stop),
            label: const Text('End Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
      ],
    );
  }

  double _calculateAverageSpeed() {
    if (trip.totalDistance == null || trip.totalDuration == null) return 0;
    if (trip.totalDuration!.inSeconds == 0) return 0;

    final hours = trip.totalDuration!.inSeconds / 3600;
    return trip.totalDistance! / hours;
  }

  String _getEstimatedArrival() {
    if (trip.startedAt == null || trip.totalDuration == null) {
      return 'N/A';
    }

    final eta = trip.startedAt!.add(trip.totalDuration!);
    final now = DateTime.now();

    if (eta.isBefore(now)) {
      return 'Arrived';
    }

    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  String _getElevationGain() {
    // This is a placeholder - you'd calculate this from route data
    return '1,234';
  }
}
