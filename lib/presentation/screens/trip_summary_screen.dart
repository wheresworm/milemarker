import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/route_provider.dart';
import '../../data/models/stop.dart';

class TripSummaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Summary')),
      body: Consumer<RouteProvider>(
        builder: (context, routeProvider, child) {
          if (routeProvider.routeData == null) {
            return Center(child: Text('No route planned yet'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route overview card
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(),
                        _buildInfoRow(
                          'Start',
                          routeProvider.startAddress ?? 'Not set',
                          Icons.play_circle_outline,
                        ),
                        _buildInfoRow(
                          'Destination',
                          routeProvider.destinationAddress ?? 'Not set',
                          Icons.location_on_outlined,
                        ),
                        _buildInfoRow(
                          'Departure',
                          _formatDateTime(routeProvider.departureTime),
                          Icons.access_time,
                        ),
                        _buildInfoRow(
                          'Estimated Arrival',
                          _formatDateTime(routeProvider.estimatedArrivalTime),
                          Icons.done,
                        ),
                        _buildInfoRow(
                          'Total Distance',
                          routeProvider.routeData!.formattedDistance,
                          Icons.straighten,
                        ),
                        _buildInfoRow(
                          'Driving Time',
                          routeProvider.routeData!.formattedDuration,
                          Icons.directions_car,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Stops list
                Text(
                  'Planned Stops',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                routeProvider.stops.isEmpty
                    ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No stops planned for this trip'),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: routeProvider.stops.length,
                      itemBuilder: (context, index) {
                        final stop = routeProvider.stops[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: _getIconForStop(stop),
                            title: Text(stop.label),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planned: ${_formatDateTime(stop.plannedTime)}',
                                ),
                                if (stop.placeName != null)
                                  Text(stop.placeName!),
                                if (stop.placeAddress != null)
                                  Text(
                                    stop.placeAddress!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Text('${stop.dwellTime.inMinutes} min'),
                          ),
                        );
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getIconForStop(Stop stop) {
    switch (stop.type) {
      case StopType.breakfast:
        return Icon(Icons.free_breakfast, color: Colors.orange);
      case StopType.lunch:
        return Icon(Icons.restaurant, color: Colors.green);
      case StopType.dinner:
        return Icon(Icons.dinner_dining, color: Colors.red);
      case StopType.custom:
        return Icon(Icons.pin_drop, color: Colors.blue);
      default:
        return Icon(Icons.place, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    final month = dateTime.month;
    final day = dateTime.day;

    return '$month/$day $hourDisplay:$minute $period';
  }
}
