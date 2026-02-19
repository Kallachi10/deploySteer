import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:steermate/providers/trip_provider.dart';
import 'package:steermate/services/sensor_service.dart';
import 'package:steermate/services/ekf_service.dart';
import 'package:steermate/services/alert_service.dart';
import 'package:steermate/services/trip_logger_service.dart';
import 'package:steermate/services/ml_service.dart';
import 'package:steermate/services/camera_service.dart';
import 'package:steermate/services/api_service.dart';
import 'package:steermate/screens/trip/trip_report_screen.dart';

class TripActiveScreen extends StatefulWidget {
  const TripActiveScreen({super.key});

  @override
  State<TripActiveScreen> createState() => _TripActiveScreenState();
}

class _TripActiveScreenState extends State<TripActiveScreen> {
  final SensorService _sensorService = SensorService();
  final EKFService _ekfService = EKFService();
  final AlertService _alertService = AlertService();
  final TripLoggerService _tripLogger = TripLoggerService();
  final MLService _mlService = MLService();
  final CameraService _cameraService = CameraService();
  
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _alertSubscription;
  
  bool _isTripActive = false;
  bool _cameraReady = false;
  double _currentSpeed = 0.0;
  double? _speedLimit;
  int _unsafeEvents = 0;
  String _statusText = 'Ready to start trip';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _mlService.initialize();
    await _alertService.initialize();
    _alertService.setSpeedLimit(_speedLimit);
  }

  Future<void> _startTrip() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    try {
      await _sensorService.start();

      if (!mounted) return;

      // Camera + ML detection (best-effort)
      final cameraOk = await _cameraService.initialize();
      if (cameraOk) {
        setState(() {
          _cameraReady = true;
        });
        await _cameraService.startCapture((detection) {
          _tripLogger.logSignDetection(detection);
          final limit = _mlService.extractSpeedLimit(detection.className);
          if (limit != null) {
            setState(() {
              _speedLimit = limit;
            });
            _alertService.setSpeedLimit(limit);
          }
        });
      }
      
      _sensorSubscription = _sensorService.sensorStream.listen((sensorData) {
        final ekfOutput = _ekfService.processSensorData(sensorData);
        if (ekfOutput != null) {
          _tripLogger.logEKFOutput(ekfOutput);
          _alertService.checkEKFOutput(
            ekfOutput,
            sensorData.lat,
            sensorData.lon,
          );
          
          setState(() {
            _currentSpeed = ekfOutput.speed * 3.6; // Convert to km/h
          });
        }
      });
      
      _alertSubscription = _alertService.alertStream.listen((alert) {
        _tripLogger.logAlert(alert);
        setState(() {
          _unsafeEvents++;
        });
        _showAlert(alert);
      });
      
      _tripLogger.startTrip();
      tripProvider.startTrip();
      
      setState(() {
        _isTripActive = true;
        _statusText = 'Trip in progress';
        _unsafeEvents = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting trip: $e')),
      );
    }
  }

  Future<void> _endTrip() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    _sensorSubscription?.cancel();
    _alertSubscription?.cancel();
    _sensorService.stop();
    await _cameraService.stopCapture();
    
    final trip = _tripLogger.endTrip();
    tripProvider.endTrip();
    
    if (trip != null) {
      // Upload trip to backend
      try {
        final tripJson = _tripLogger.tripToJson(trip);
        final response = await ApiService.uploadTrip(tripJson);
        
        if (response.statusCode == 201) {
          final tripId = response.data['id'];
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripReportScreen(tripId: tripId),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading trip: $e')),
          );
        }
      }
    }
    
    setState(() {
      _isTripActive = false;
      _statusText = 'Trip ended';
      _currentSpeed = 0.0;
    });
  }

  void _showAlert(AlertEvent alert) {
    String message;
    switch (alert.type) {
      case AlertType.hardBrake:
        message = 'Hard braking detected!';
        break;
      case AlertType.harshAccel:
        message = 'Harsh acceleration detected!';
        break;
      case AlertType.unsafeCurve:
        message = 'Unsafe cornering detected!';
        break;
      case AlertType.overspeed:
        message = 'Overspeed detected!';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _alertSubscription?.cancel();
    _sensorService.dispose();
    _alertService.dispose();
    _mlService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_car,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              if (_isTripActive) ...[
                _buildSpeedDisplay(),
                const SizedBox(height: 32),
                _buildCameraPreview(),
                const SizedBox(height: 32),
                _buildStats(),
              ],
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isTripActive ? _endTrip : _startTrip,
                icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
                label: Text(_isTripActive ? 'End Trip' : 'Start Trip'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: _isTripActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDisplay() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 4),
      ),
      child: Column(
        children: [
          Text(
            _currentSpeed.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'km/h',
            style: TextStyle(fontSize: 16),
          ),
          if (_speedLimit != null) ...[
            const SizedBox(height: 8),
            Text(
              'Limit: ${_speedLimit!.toStringAsFixed(0)} km/h',
              style: TextStyle(
                fontSize: 14,
                color: _currentSpeed > _speedLimit! ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Unsafe Events', _unsafeEvents.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraService.controller;

    if (!_cameraReady || controller == null || !controller.value.isInitialized) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Initializing camera...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
