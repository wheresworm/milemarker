import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import 'animated_counter.dart';

class SpeedDisplayOverlay extends StatelessWidget {
  final double speed;
  final double distance;
  final Duration duration;

  const SpeedDisplayOverlay({
    super.key,
    required this.speed,
    required this.distance,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speed
          _buildStatistic(
            icon: Icons.speed,
            value: Formatters.formatSpeed(speed),
            color: Colors.blue,
          ),
          const SizedBox(width: 20),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(width: 20),
          // Distance
          _buildStatistic(
            icon: Icons.straighten,
            value: Formatters.formatDistance(distance),
            color: Colors.green,
          ),
          const SizedBox(width: 20),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(width: 20),
          // Duration
          _buildStatistic(
            icon: Icons.timer,
            value: Formatters.formatDuration(duration),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    // Extract numeric value and suffix from the formatted string
    final match = RegExp(r'([\d.]+)(.*)').firstMatch(value);
    final numericValue = double.tryParse(match?.group(1) ?? '0') ?? 0;
    final suffix = match?.group(2) ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        AnimatedCounter(
          value: numericValue,
          suffix: suffix,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
