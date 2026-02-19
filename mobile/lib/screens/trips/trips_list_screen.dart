import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:steermate/providers/trip_provider.dart';
import 'package:steermate/screens/trip/trip_report_screen.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({super.key});

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
      ),
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, _) {
          if (tripProvider.trips.isEmpty) {
            return const Center(
              child: Text('No trips yet. Start your first trip!'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tripProvider.loadTrips(),
            child: ListView.builder(
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                return _buildTripCard(context, trip);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final startTime = trip['start_time'] != null
        ? DateTime.parse(trip['start_time'])
        : null;
    final distanceKm = trip['distance_m'] != null
        ? (trip['distance_m'] as num) / 1000.0
        : 0.0;
    final unsafeEvents = trip['unsafe_events'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.directions_car, size: 40),
        title: Text(
          startTime != null
              ? DateFormat('MMM dd, yyyy - HH:mm').format(startTime)
              : 'Unknown date',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Distance: ${distanceKm.toStringAsFixed(2)} km'),
            Text('Unsafe events: $unsafeEvents'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripReportScreen(tripId: trip['id']),
            ),
          );
        },
      ),
    );
  }
}
