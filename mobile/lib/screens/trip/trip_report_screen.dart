import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:steermate/providers/trip_provider.dart';

class TripReportScreen extends StatefulWidget {
  final int tripId;

  const TripReportScreen({super.key, required this.tripId});

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final report = await tripProvider.getReport(widget.tripId);
    
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Failed to load report'))
              : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    final summary = _report!['summary'] as Map<String, dynamic>;
    final events = _report!['events'] as List<dynamic>;
    final analytics = _report!['analytics'] as Map<String, dynamic>;
    final recommendations = analytics['recommendations'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: 16),
          _buildEventsCard(events),
          const SizedBox(height: 16),
          _buildRecommendationsCard(recommendations),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Distance', '${summary['distance_km']} km'),
            _buildSummaryRow('Duration', '${summary['duration_seconds']} s'),
            _buildSummaryRow('Avg Speed', '${summary['avg_speed_kmh']} km/h'),
            _buildSummaryRow('Max Speed', '${summary['max_speed_kmh']} km/h'),
            _buildSummaryRow('Unsafe Events', '${summary['unsafe_events']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventsCard(List<dynamic> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              const Text('No events recorded')
            else
              ...events.map((event) => _buildEventItem(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final timestamp = event['timestamp'] != null
        ? DateTime.parse(event['timestamp'])
        : null;
    
    return ListTile(
      leading: Icon(_getEventIcon(type), color: Colors.red),
      title: Text(_formatEventType(type)),
      subtitle: timestamp != null
          ? Text(DateFormat('HH:mm:ss').format(timestamp))
          : null,
      trailing: Text('${event['speed_kmh']} km/h'),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'hard_brake':
        return Icons.stop;
      case 'harsh_accel':
        return Icons.speed;
      case 'unsafe_curve':
        return Icons.turn_right;
      case 'overspeed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _formatEventType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildRecommendationsCard(List<dynamic> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec as String)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
