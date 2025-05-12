import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/route_provider.dart';
import '../../core/utils/logger.dart';

class DepartureTimeSelector extends StatefulWidget {
  final DateTime departureTime;
  final Function(DateTime) onTimeChanged;

  const DepartureTimeSelector({
    super.key,
    required this.departureTime,
    required this.onTimeChanged,
  });

  @override
  State<DepartureTimeSelector> createState() => _DepartureTimeSelectorState();
}

class _DepartureTimeSelectorState extends State<DepartureTimeSelector> {
  late double _sliderValue;
  final int _stepsPerHour = 4; // 15-minute intervals

  @override
  void initState() {
    super.initState();
    // Initialize slider value based on current departure time
    _sliderValue = _timeToSliderValue(widget.departureTime);
  }

  @override
  void didUpdateWidget(DepartureTimeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departureTime != widget.departureTime) {
      setState(() {
        _sliderValue = _timeToSliderValue(widget.departureTime);
      });
    }
  }

  // Convert time to a slider value (0-24*steps)
  double _timeToSliderValue(DateTime time) {
    return (time.hour * _stepsPerHour + (time.minute / (60 / _stepsPerHour)))
        .toDouble();
  }

  // Convert slider value to time
  DateTime _sliderValueToTime(double value) {
    final now = DateTime.now();
    final hour = (value ~/ _stepsPerHour).toInt();
    final minute = ((value % _stepsPerHour) * (60 / _stepsPerHour)).toInt();

    // Create a new DateTime with today's date and the selected time
    final selectedTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the selected time is already passed today, use tomorrow
    return selectedTime.isBefore(now)
        ? selectedTime.add(const Duration(days: 1))
        : selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue.withAlpha(76),
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withAlpha(102),
            valueIndicatorColor: Colors.blue,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 24 * _stepsPerHour.toDouble(),
            divisions: 24 * _stepsPerHour,
            label: _formatTimeFromSlider(_sliderValue),
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
            onChangeEnd: (value) {
              final newTime = _sliderValueToTime(value);
              AppLogger.info(
                'DepartureTimeSelector: Time changed to ${_formatTimeFromSlider(value)}',
              );

              // This updates the provider
              widget.onTimeChanged(newTime);

              // Get the route provider and force a route calculation
              final routeProvider = Provider.of<RouteProvider>(
                context,
                listen: false,
              );

              if (routeProvider.startLocation != null &&
                  routeProvider.destinationLocation != null) {
                // Show a snackbar to indicate recalculation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updating route for new departure time...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                // Immediately calculate the route with the new time
                Future.delayed(const Duration(milliseconds: 200), () {
                  routeProvider.calculateRoute();
                });
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 AM',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '6 AM',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '12 PM',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '6 PM',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                '11:59 PM',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeFromSlider(double value) {
    final time = _sliderValueToTime(value);
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourDisplay = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hourDisplay:$minute $period';
  }
}
