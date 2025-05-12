import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/stop.dart';
import '../../data/providers/route_provider.dart';
import 'stop_list.dart';
import 'departure_time_selector.dart';

class BottomSheetContent extends StatelessWidget {
  final Function()? onAddCustomStop;

  const BottomSheetContent({super.key, this.onAddCustomStop});

  @override
  Widget build(BuildContext context) {
    // Using Consumer to ensure the widget rebuilds when the provider changes
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Departure time section with more prominent display
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Departure: ${_formatTime(routeProvider.departureTime)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    // Show the day if it's not today
                    if (_isNotToday(routeProvider.departureTime))
                      Text(
                        ' (${_formatDate(routeProvider.departureTime)})',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),

                DepartureTimeSelector(
                  departureTime: routeProvider.departureTime,
                  onTimeChanged: (time) => routeProvider.setDepartureTime(time),
                ),

                // Find best departure time button
                if (routeProvider.startLocation != null &&
                    routeProvider.destinationLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: const Text('Find Best Departure Time'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                        ),
                        onPressed: () async {
                          // Show loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Finding optimal departure time...',
                              ),
                              duration: Duration(seconds: 10),
                            ),
                          );

                          final optimalTime =
                              await routeProvider.findOptimalDepartureTime();

                          if (optimalTime != null) {
                            routeProvider.setDepartureTime(optimalTime);
                            routeProvider.calculateRoute();

                            // Show success message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Found optimal departure time: ${_formatTime(optimalTime)}',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {
                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not find optimal departure time',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Arrival information (only show when we have a route)
                if (routeProvider.routeData != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flag,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Arrival: ${routeProvider.formattedArrivalTime}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Travel time
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Travel: ${routeProvider.routeData!.formattedDuration}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            // Distance
                            Row(
                              children: [
                                const Icon(Icons.place, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Distance: ${routeProvider.routeData!.formattedDistance}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Stops section
                const Text(
                  'Planned Stops:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 8),

                // Meal stop buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMealStopButton(
                      context,
                      'Breakfast',
                      StopType.breakfast,
                      routeProvider,
                    ),
                    _buildMealStopButton(
                      context,
                      'Lunch',
                      StopType.lunch,
                      routeProvider,
                    ),
                    _buildMealStopButton(
                      context,
                      'Dinner',
                      StopType.dinner,
                      routeProvider,
                    ),
                  ],
                ),

                // Add automatic meal stops button
                if (routeProvider.routeData != null &&
                    routeProvider.stops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Add Meal Stops For This Trip'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          routeProvider.addMealStopsBasedOnDeparture();
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Stops list
                if (routeProvider.stops.isNotEmpty)
                  SizedBox(
                    height: 200, // Fixed height for the stops list
                    child: StopList(
                      stops: routeProvider.stops,
                      onDelete: (stopId) => routeProvider.removeStop(stopId),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to build meal stop buttons
  Widget _buildMealStopButton(
    BuildContext context,
    String label,
    StopType type,
    RouteProvider provider,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => provider.addMealStop(type),
      child: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }

  // Helper to format time
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hourDisplay:$minute $period';
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Helper to check if date is not today
  bool _isNotToday(DateTime date) {
    final now = DateTime.now();
    return date.day != now.day ||
        date.month != now.month ||
        date.year != now.year;
  }
}
