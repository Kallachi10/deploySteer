import 'dart:math' as math;

import 'package:steermate/services/ekf_service.dart';
import 'package:steermate/services/alert_service.dart';

class TripData {
  final DateTime startTime;
  DateTime? endTime;
  final List<EKFOutput> ekfOutputs = [];
  final List<AlertEvent> alerts = [];
  final List<SignDetection> signDetections = [];

  TripData({required this.startTime});
  
  double get durationSeconds {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds.toDouble();
  }
  
  double get distanceM {
    if (ekfOutputs.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < ekfOutputs.length; i++) {
      final dx = ekfOutputs[i].px - ekfOutputs[i-1].px;
      final dy = ekfOutputs[i].py - ekfOutputs[i-1].py;
      final d2 = (dx * dx) + (dy * dy);
      if (d2.isNaN || d2.isInfinite || d2 < 0) continue;
      total += math.sqrt(d2);
    }
    return total;
  }
  
  double get avgSpeedMs {
    if (ekfOutputs.isEmpty) return 0;
    final sum = ekfOutputs.map((e) => e.speed).reduce((a, b) => a + b);
    return sum / ekfOutputs.length;
  }
  
  double get maxSpeedMs {
    if (ekfOutputs.isEmpty) return 0;
    return ekfOutputs.map((e) => e.speed).reduce((a, b) => a > b ? a : b);
  }
  
  int get unsafeEventsCount => alerts.length;
}

class SignDetection {
  final DateTime timestamp;
  final String className;
  final double confidence;
  final Map<String, dynamic> bbox;

  SignDetection({
    required this.timestamp,
    required this.className,
    required this.confidence,
    required this.bbox,
  });
}

class TripLoggerService {
  TripData? _currentTrip;
  
  TripData? get currentTrip => _currentTrip;
  
  void startTrip() {
    _currentTrip = TripData(startTime: DateTime.now());
  }
  
  void logEKFOutput(EKFOutput output) {
    _currentTrip?.ekfOutputs.add(output);
  }
  
  void logAlert(AlertEvent alert) {
    _currentTrip?.alerts.add(alert);
  }
  
  void logSignDetection(SignDetection detection) {
    _currentTrip?.signDetections.add(detection);
  }
  
  TripData? endTrip() {
    if (_currentTrip == null) return null;
    _currentTrip!.endTime = DateTime.now();
    final trip = _currentTrip;
    _currentTrip = null;
    return trip;
  }
  
  Map<String, dynamic> tripToJson(TripData trip) {
    return {
      'start_time': trip.startTime.toIso8601String(),
      'end_time': trip.endTime?.toIso8601String(),
      'duration_seconds': trip.durationSeconds.toInt(),
      'distance_m': trip.distanceM,
      'avg_speed_m_s': trip.avgSpeedMs,
      'max_speed_m_s': trip.maxSpeedMs,
      'unsafe_events': trip.unsafeEventsCount,
      'events': trip.alerts.map((alert) => {
        'event_type': _alertTypeToString(alert.type),
        'timestamp': alert.timestamp.toIso8601String(),
        'lat': alert.lat ?? 0.0,
        'lon': alert.lon ?? 0.0,
        'speed_m_s': (alert.speed ?? 0.0) / 3.6,
        'accel_m_s2': alert.acceleration ?? 0.0,
      }).toList(),
      'sign_detections': trip.signDetections.map((sign) => {
        'ts': sign.timestamp.toIso8601String(),
        'class_name': sign.className,
        'confidence': sign.confidence,
        'bbox': sign.bbox,
      }).toList(),
    };
  }
  
  String _alertTypeToString(AlertType type) {
    switch (type) {
      case AlertType.hardBrake:
        return 'hard_brake';
      case AlertType.harshAccel:
        return 'harsh_accel';
      case AlertType.unsafeCurve:
        return 'unsafe_curve';
      case AlertType.overspeed:
        return 'overspeed';
    }
  }
}
