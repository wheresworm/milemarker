import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripSummaryScreen extends StatelessWidget {
  final String start;
  final String end;
  final TimeOfDay? departureTime;
  final String durationText;
  final String distanceText;
  final String etaFormatted;

  const TripSummaryScreen({
    required this.start,
    required this.end,
    required this.departureTime,
    required this.durationText,
    required this.distanceText,
    required this.etaFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDeparture =
        departureTime == null
            ? 'Not set'
            : DateFormat.jm().format(
              DateTime(0, 0, 0, departureTime!.hour, departureTime!.minute),
            );

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From:", style: Theme.of(context).textTheme.labelMedium),
            Text(start, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            Text("To:", style: Theme.of(context).textTheme.labelMedium),
            Text(end, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),

            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 10),
                Text("Departure: $formattedDeparture"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 10),
                Text("Drive Time: $durationText"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.directions_car),
                const SizedBox(width: 10),
                Text("Distance: $distanceText"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 10),
                Text("ETA: $etaFormatted"),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("View on Map"),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
