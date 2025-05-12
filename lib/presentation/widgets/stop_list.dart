import 'package:flutter/material.dart';
import '../../data/models/stop.dart';

class StopList extends StatelessWidget {
  final List<Stop> stops;
  final Function(String) onDelete;

  const StopList({Key? key, required this.stops, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        return Dismissible(
          key: Key(stop.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(stop.id),
          child: ListTile(
            title: Text(stop.label),
            subtitle: Text(_formatTime(stop.plannedTime)),
            trailing: Text('${stop.dwellTime.inMinutes} min'),
          ),
        );
      },
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
}
