import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/trip.dart';
import '../../core/services/database_service.dart';
import '../widgets/trip_card.dart';
import '../widgets/empty_state.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  String _sortBy = 'recent'; // recent, distance, duration
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final trips = await _databaseService.getAllTrips();

      // Sort trips
      switch (_sortBy) {
        case 'distance':
          trips.sort((a, b) {
            if (b.distance == null) return a.distance == null ? 0 : -1;
            if (a.distance == null) return 1;
            return b.distance!.compareTo(a.distance!);
          });
          break;
        case 'duration':
          trips.sort((a, b) {
            if (b.duration == null) return a.duration == null ? 0 : -1;
            if (a.duration == null) return 1;
            return b.duration!.compareTo(a.duration!);
          });
          break;
        default:
          trips.sort((a, b) {
            if (b.startTime == null) return a.startTime == null ? 0 : -1;
            if (a.startTime == null) return 1;
            return b.startTime!.compareTo(a.startTime!);
          });
      }

      setState(() {
        _trips = trips;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trips: $e')),
        );
      }
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Removed unnecessary non-null assertion
      await _databaseService.deleteTrip(trip.id);
      _loadTrips();
    }
  }

  void _shareTrip(Trip trip) {
    // TODO: Implement share functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed unused theme variable

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trips'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadTrips();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Most Recent'),
              ),
              const PopupMenuItem(
                value: 'distance',
                child: Text('Longest Distance'),
              ),
              const PopupMenuItem(
                value: 'duration',
                child: Text('Longest Duration'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _trips.isEmpty
                ? EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No trips yet',
                    subtitle: 'Start tracking to see your trips here',
                    onRefresh: _loadTrips,
                  )
                : AnimatedList(
                    initialItemCount: _trips.length,
                    itemBuilder: (context, index, animation) {
                      final trip = _trips[index];

                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOut)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: TripCard(
                            trip: trip,
                            onTap: () => _navigateToTripDetails(trip),
                            onDelete: () => _deleteTrip(trip),
                            onShare: () => _shareTrip(trip),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _navigateToTripDetails(Trip trip) {
    // TODO: Navigate to trip details screen
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip details coming soon!')),
    );
  }
}
