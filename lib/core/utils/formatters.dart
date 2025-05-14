import 'package:intl/intl.dart';

class Formatters {
  static String formatDistance(double meters, {String units = 'imperial'}) {
    if (units == 'imperial') {
      final miles = meters * 0.000621371;
      if (miles < 0.1) {
        final feet = meters * 3.28084;
        return '${feet.toStringAsFixed(0)} ft';
      }
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      if (meters < 1000) {
        return '${meters.toStringAsFixed(0)} m';
      }
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  static String formatSpeed(
    double metersPerSecond, {
    String units = 'imperial',
  }) {
    if (units == 'imperial') {
      final mph = metersPerSecond * 2.23694;
      return '${mph.toStringAsFixed(0)} mph';
    } else {
      final kmh = metersPerSecond * 3.6;
      return '${kmh.toStringAsFixed(0)} km/h';
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today ${DateFormat.jm().format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday ${DateFormat.jm().format(dateTime)}';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').add_jm().format(dateTime);
    } else {
      return DateFormat('MMM d, y').add_jm().format(dateTime);
    }
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  static String formatElevation(double meters, {String units = 'imperial'}) {
    if (units == 'imperial') {
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)} ft';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  static String formatNumber(num value, {int decimals = 0}) {
    final formatter = NumberFormat.decimalPattern();
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return formatter.format(value);
  }
}
