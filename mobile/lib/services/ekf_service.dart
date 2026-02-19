import 'dart:math';
import 'package:steermate/services/sensor_service.dart';
import 'package:steermate/services/ahrs_service.dart';

class EKFState {
  double px; // position x (m)
  double py; // position y (m)
  double vx; // velocity x (m/s)
  double vy; // velocity y (m/s)
  double bax; // accelerometer bias x
  double bay; // accelerometer bias y
  
  EKFState({
    this.px = 0.0,
    this.py = 0.0,
    this.vx = 0.0,
    this.vy = 0.0,
    this.bax = 0.0,
    this.bay = 0.0,
  });
  
  List<double> toList() => [px, py, vx, vy, bax, bay];
  
  EKFState copy() => EKFState(
    px: px, py: py, vx: vx, vy: vy, bax: bax, bay: bay,
  );
}

class EKFOutput {
  final DateTime timestamp;
  final double px;
  final double py;
  final double vx;
  final double vy;
  final double speed; // magnitude of velocity
  final double accelLong; // longitudinal acceleration
  final double accelLat; // lateral acceleration
  
  EKFOutput({
    required this.timestamp,
    required this.px,
    required this.py,
    required this.vx,
    required this.vy,
    required this.speed,
    required this.accelLong,
    required this.accelLat,
  });
}

class EKFService {
  EKFState _state = EKFState();
  List<List<double>> _P = List.generate(6, (i) => List.filled(6, 0.0)); // Covariance matrix
  
  MadgwickAHRS _ahrs = MadgwickAHRS();
  
  // Process noise covariance
  final List<List<double>> Q = [
    [0.1, 0, 0, 0, 0, 0],
    [0, 0.1, 0, 0, 0, 0],
    [0, 0, 0.5, 0, 0, 0],
    [0, 0, 0, 0.5, 0, 0],
    [0, 0, 0, 0, 1e-4, 0],
    [0, 0, 0, 0, 0, 1e-4],
  ];
  
  // Measurement noise covariance
  final double R_pos = 25.0; // 5 m std
  final double R_speed = 0.25; // 0.5 m/s std
  
  DateTime? _lastUpdateTime;

  // Local tangent-plane origin for converting lat/lon -> meters.
  double? _originLat;
  double? _originLon;
  static const double _earthRadiusM = 6378137.0;

  // Keep last vehicle-frame accelerations for output/alerting.
  double _lastAxVehicle = 0.0;
  double _lastAyVehicle = 0.0;
  
  EKFService() {
    // Initialize covariance matrix
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        _P[i][j] = (i == j) ? 1.0 : 0.0;
      }
    }
  }
  
  EKFOutput? processSensorData(SensorData data) {
    final now = data.timestamp;
    final dt = _lastUpdateTime != null
      ? (now.difference(_lastUpdateTime!).inMicroseconds / 1000000.0)
      : 1.0 / 50.0; // Default 50Hz
    
    if (dt <= 0 || dt > 1.0) {
      _lastUpdateTime = now;
      return null;
    }
    
    // Update AHRS if all sensors available
    if (data.accelX != null && data.accelY != null && data.accelZ != null &&
        data.gyroX != null && data.gyroY != null && data.gyroZ != null &&
        data.magX != null && data.magY != null && data.magZ != null) {
      _ahrs.update(data.gyroX!, data.gyroY!, data.gyroZ!,
                   data.accelX!, data.accelY!, data.accelZ!,
                   data.magX!, data.magY!, data.magZ!);
    }
    
    // Predict step (using IMU data if available)
    if (data.accelX != null && data.accelY != null && data.gyroZ != null) {
      // Transform accelerations to vehicle frame using AHRS
      final euler = _ahrs.getEuler();
      final yaw = euler[0];
      final cosYaw = cos(yaw);
      final sinYaw = sin(yaw);
      
      // Assuming phone forward is +Y, right is +X
      // Vehicle forward +X, right +Y
      final accelVehicleX = data.accelX! * cosYaw - data.accelY! * sinYaw;
      final accelVehicleY = data.accelX! * sinYaw + data.accelY! * cosYaw;

      // Store for output (simple low-pass to reduce noise).
      const alpha = 0.2;
      _lastAxVehicle = (1 - alpha) * _lastAxVehicle + alpha * accelVehicleX;
      _lastAyVehicle = (1 - alpha) * _lastAyVehicle + alpha * accelVehicleY;
      
      _predict(dt, accelVehicleX, accelVehicleY, data.gyroZ!);
    }
    
    // Update step (using GPS data if available)
    if (data.lat != null && data.lon != null && data.speed != null && data.heading != null) {
      _update(data.lat!, data.lon!, data.speed!, data.heading!);
    }
    
    _lastUpdateTime = now;
    
    // Calculate outputs
    final speed = sqrt(_state.vx * _state.vx + _state.vy * _state.vy);
    
    // Output accelerations in vehicle frame (longitudinal/lateral)
    // Using the transformed IMU acceleration; EKF bias/RTS smoothing can be added later.
    final accelLong = _lastAxVehicle;
    final accelLat = _lastAyVehicle;
    
    return EKFOutput(
      timestamp: now,
      px: _state.px,
      py: _state.py,
      vx: _state.vx,
      vy: _state.vy,
      speed: speed,
      accelLong: accelLong,
      accelLat: accelLat,
    );
  }
  
  void _predict(double dt, double accelX, double accelY, double gyroZ) {
    // Simple constant velocity model with acceleration input
    // State: [px, py, vx, vy, bax, bay]
    
    // Remove bias from accelerometer
    final ax = accelX - _state.bax;
    final ay = accelY - _state.bay;
    
    // Update state
    _state.px += _state.vx * dt + 0.5 * ax * dt * dt;
    _state.py += _state.vy * dt + 0.5 * ay * dt * dt;
    _state.vx += ax * dt;
    _state.vy += ay * dt;
    
    // Update covariance (simplified)
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        _P[i][j] += Q[i][j] * dt;
      }
    }
  }
  
  void _update(double lat, double lon, double speed, double heading) {
    // Convert GPS to local meters (equirectangular approximation around origin).
    _originLat ??= lat;
    _originLon ??= lon;
    final lat0Rad = (_originLat! * pi) / 180.0;
    final dLat = ((lat - _originLat!) * pi) / 180.0;
    final dLon = ((lon - _originLon!) * pi) / 180.0;
    final gpsX = dLon * cos(lat0Rad) * _earthRadiusM;
    final gpsY = dLat * _earthRadiusM;
    
    // Measurement: [px, py, speed]
    final headingRad = heading * pi / 180.0;
    // Heading degrees: 0 = north, 90 = east
    final gpsVx = speed * sin(headingRad);
    final gpsVy = speed * cos(headingRad);
    
    // Innovation
    final yx = gpsX - _state.px;
    final yy = gpsY - _state.py;
    final yvx = gpsVx - _state.vx;
    final yvy = gpsVy - _state.vy;
    
    // Kalman gain (simplified)
    final Kpos = 0.2;
    final Kvel = 0.3;
    
    // Update state
    _state.px += Kpos * yx;
    _state.py += Kpos * yy;
    _state.vx += Kvel * yvx;
    _state.vy += Kvel * yvy;
  }
  
  void reset() {
    _state = EKFState();
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        _P[i][j] = (i == j) ? 1.0 : 0.0;
      }
    }
    _lastUpdateTime = null;
    _originLat = null;
    _originLon = null;
    _lastAxVehicle = 0.0;
    _lastAyVehicle = 0.0;
  }
}
