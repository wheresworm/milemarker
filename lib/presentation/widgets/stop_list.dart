import 'package:flutter/material.dart';
import '../../core/models/stop.dart';
import 'stop_card.dart';

class StopList extends StatefulWidget {
  final List<Stop> stops;
  final Function(List<Stop>) onReorder;
  final Function(String) onRemove;
  final Function(Stop) onStopTap;

  const StopList({
    super.key,
    required this.stops,
    required this.onReorder,
    required this.onRemove,
    required this.onStopTap,
  });

  @override
  State<StopList> createState() => _StopListState();
}

class _StopListState extends State<StopList> {
  @override
  Widget build(BuildContext context) {
    if (widget.stops.isEmpty) {
      return const Center(
        child: Text(
          'No stops added yet\nTap the + button to add stops',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: widget.stops.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;

        final stops = List<Stop>.from(widget.stops);
        final stop = stops.removeAt(oldIndex);
        stops.insert(newIndex, stop);

        widget.onReorder(stops);
      },
      itemBuilder: (context, index) {
        final stop = widget.stops[index];
        final isFirst = index == 0;
        final isLast = index == widget.stops.length - 1;

        return StopCard(
          key: ValueKey(stop.id),
          stop: stop,
          onTap: () => widget.onStopTap(stop),
          // Only pass the onRemove handler if it's not the first or last stop
          onDelete: isFirst || isLast
              ? null
              : () => widget.onRemove(stop
                  .id), // Changed from onRemove to onDelete if that's what StopCard accepts
        );
      },
    );
  }
}
