import 'package:flutter/material.dart';
import '../../core/models/trip.dart';
import '../../core/utils/formatters.dart';

class TripBottomSheet extends StatefulWidget {
  final bool isTracking;
  final Trip? currentTrip;
  final AnimationController animationController;
  final VoidCallback onExpand;

  const TripBottomSheet({
    super.key,
    required this.isTracking,
    required this.currentTrip,
    required this.animationController,
    required this.onExpand,
  });

  @override
  State<TripBottomSheet> createState() => _TripBottomSheetState();
}

class _TripBottomSheetState extends State<TripBottomSheet> {
  bool _isExpanded = false;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _heightAnimation = Tween<double>(begin: 120.0, end: 400.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        widget.animationController.forward();
      } else {
        widget.animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!widget.isTracking || widget.currentTrip == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) {
            _toggleExpansion();
          } else if (details.primaryDelta! > 10) {
            _toggleExpansion();
          }
        },
        child: AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              height: _heightAnimation.value + bottomPadding,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Quick stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          icon: Icons.speed,
                          value: Formatters.formatSpeed(
                            widget.currentTrip!.averageSpeed,
                          ),
                          label: 'Speed',
                          color: Colors.blue,
                        ),
                        _buildQuickStat(
                          icon: Icons.straighten,
                          value: Formatters.formatDistance(
                            widget.currentTrip!.distance,
                          ),
                          label: 'Distance',
                          color: Colors.green,
                        ),
                        _buildQuickStat(
                          icon: Icons.timer,
                          value: Formatters.formatDuration(
                            widget.currentTrip!.duration,
                          ),
                          label: 'Duration',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  if (_isExpanded) ...[
                    const Divider(height: 32),
                    // Expanded content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Start Time',
                              Formatters.formatDateTime(
                                widget.currentTrip!.startTime,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Max Speed',
                              Formatters.formatSpeed(
                                widget.currentTrip!.maxSpeed,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Waypoints',
                              '${widget.currentTrip!.route.length}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: bottomPadding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
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
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
