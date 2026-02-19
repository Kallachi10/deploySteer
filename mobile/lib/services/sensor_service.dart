import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorData {
  final DateTime timestamp;
  final double? lat;
  final double? lon;
  final double? speed; // m/s
  final double? heading;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final double? magX;
  final double? magY;
  final double? magZ;

  SensorData({
    required this.timestamp,
    this.lat,
    this.lon,
    this.speed,
    this.heading,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.magX,
    this.magY,
    this.magZ,
  });
}

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _emitTimer;
  
  final StreamController<SensorData> _sensorController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorStream => _sensorController.stream;
  
  AccelerometerEvent? _lastAccel;
  GyroscopeEvent? _lastGyro;
  MagnetometerEvent? _lastMag;
  Position? _lastPosition;
  
  bool _isRunning = false;

  final int emitHz;

  SensorService({this.emitHz = 50});

  Future<bool> requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> start() async {
    if (_isRunning) return;
    
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    _isRunning = true;

    // Start accelerometer
    try {
      _accelSubscription = accelerometerEventStream().listen((event) {
        _lastAccel = event;
      });
    } catch (e) {
      // Accelerometer not available
    }

    // Start gyroscope
    try {
      _gyroSubscription = gyroscopeEventStream().listen((event) {
        _lastGyro = event;
      });
    } catch (e) {
      // Gyroscope not available
    }

    // Start magnetometer
    try {
      _magSubscription = magnetometerEventStream().listen((event) {
        _lastMag = event;
      });
    } catch (e) {
      // Magnetometer not available
    }

    // Start GPS
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // meters
      ),
    ).listen((position) {
      _lastPosition = position;
    });

    // Emit a fused snapshot at a stable rate.
    final intervalMs = (1000 / emitHz).round().clamp(5, 1000);
    _emitTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _emitSensorData();
    });
  }

  void _emitSensorData() {
    if (!_isRunning) return;
    
    _sensorController.add(SensorData(
      timestamp: DateTime.now(),
      lat: _lastPosition?.latitude,
      lon: _lastPosition?.longitude,
      speed: _lastPosition?.speed, // m/s
      heading: _lastPosition?.heading,
      accelX: _lastAccel?.x,
      accelY: _lastAccel?.y,
      accelZ: _lastAccel?.z,
      gyroX: _lastGyro?.x,
      gyroY: _lastGyro?.y,
      gyroZ: _lastGyro?.z,
      magX: _lastMag?.x,
      magY: _lastMag?.y,
      magZ: _lastMag?.z,
    ));
  }

  void stop() {
    _isRunning = false;
    _emitTimer?.cancel();
    _emitTimer = null;
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _magSubscription?.cancel();
    _gpsSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
    _magSubscription = null;
    _gpsSubscription = null;
  }

  void dispose() {
    stop();
    _sensorController.close();
  }
}
