import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:steermate/services/ekf_service.dart';
import 'package:steermate/services/settings_service.dart';

enum AlertType {
  hardBrake,
  harshAccel,
  unsafeCurve,
  overspeed,
}

class AlertEvent {
  final DateTime timestamp;
  final AlertType type;
  final double? speed;
  final double? acceleration;
  final double? lat;
  final double? lon;

  AlertEvent({
    required this.timestamp,
    required this.type,
    this.speed,
    this.acceleration,
    this.lat,
    this.lon,
  });
}

class AlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AlertEvent> _alertController = StreamController<AlertEvent>.broadcast();
  Stream<AlertEvent> get alertStream => _alertController.stream;
  
  // Thresholds (loaded from settings)
  // Store hard brake threshold as positive magnitude; apply sign when comparing.
  double hardBrakeThresholdAbs = 4.0; // m/s²
  double harshAccelThreshold = 4.0; // m/s²
  double unsafeCurveThreshold = 2.5; // m/s²
  double overspeedMargin = 5.0; // km/h
  
  double? _currentSpeedLimit; // km/h
  DateTime? _lastHardBrakeTime;
  DateTime? _lastHarshAccelTime;
  DateTime? _lastUnsafeCurveTime;
  DateTime? _lastOverspeedTime;

  DateTime? _hardBrakeStart;
  DateTime? _harshAccelStart;
  DateTime? _unsafeCurveStart;
  DateTime? _overspeedStart;

  final Duration _hardBrakeMinDuration = const Duration(milliseconds: 500);
  final Duration _harshAccelMinDuration = const Duration(milliseconds: 400);
  final Duration _unsafeCurveMinDuration = const Duration(milliseconds: 400);
  final Duration _overspeedMinDuration = const Duration(milliseconds: 800);
  
  final Duration _alertCooldown = const Duration(seconds: 2);
  
  bool _isEnabled = true;
  bool _hapticsEnabled = true;
  bool _audioEnabled = false;

  Future<void> initialize() async {
    hardBrakeThresholdAbs = await SettingsService.getHardBrakeThreshold();
    harshAccelThreshold = await SettingsService.getHarshAccelThreshold();
    unsafeCurveThreshold = await SettingsService.getCurveThreshold();
    overspeedMargin = await SettingsService.getOverspeedMargin();

    _hapticsEnabled = await SettingsService.getHapticsEnabled();
    _audioEnabled = await SettingsService.getAudioEnabled();
  }

  void setSpeedLimit(double? limitKmh) {
    _currentSpeedLimit = limitKmh;
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void checkEKFOutput(EKFOutput output, double? lat, double? lon) {
    if (!_isEnabled) return;

    final now = output.timestamp;
    final speedKmh = output.speed * 3.6;

    // Reduce false positives at standstill / very low speed.
    final moving = speedKmh >= 8.0;

    // Hard braking
    if (moving && output.accelLong < -hardBrakeThresholdAbs) {
      _hardBrakeStart ??= now;
      final sustained = now.difference(_hardBrakeStart!) >= _hardBrakeMinDuration;
      final cooledDown = _lastHardBrakeTime == null || now.difference(_lastHardBrakeTime!) > _alertCooldown;
      if (sustained && cooledDown) {
        _triggerAlert(AlertEvent(
          timestamp: now,
          type: AlertType.hardBrake,
          speed: speedKmh,
          acceleration: output.accelLong,
          lat: lat,
          lon: lon,
        ));
        _lastHardBrakeTime = now;
        _hardBrakeStart = null;
      }
    } else {
      _hardBrakeStart = null;
    }

    // Harsh acceleration
    if (moving && output.accelLong > harshAccelThreshold) {
      _harshAccelStart ??= now;
      final sustained = now.difference(_harshAccelStart!) >= _harshAccelMinDuration;
      final cooledDown = _lastHarshAccelTime == null || now.difference(_lastHarshAccelTime!) > _alertCooldown;
      if (sustained && cooledDown) {
        _triggerAlert(AlertEvent(
          timestamp: now,
          type: AlertType.harshAccel,
          speed: speedKmh,
          acceleration: output.accelLong,
          lat: lat,
          lon: lon,
        ));
        _lastHarshAccelTime = now;
        _harshAccelStart = null;
      }
    } else {
      _harshAccelStart = null;
    }

    // Unsafe cornering
    if (moving && output.accelLat.abs() > unsafeCurveThreshold) {
      _unsafeCurveStart ??= now;
      final sustained = now.difference(_unsafeCurveStart!) >= _unsafeCurveMinDuration;
      final cooledDown = _lastUnsafeCurveTime == null || now.difference(_lastUnsafeCurveTime!) > _alertCooldown;
      if (sustained && cooledDown) {
        _triggerAlert(AlertEvent(
          timestamp: now,
          type: AlertType.unsafeCurve,
          speed: speedKmh,
          acceleration: output.accelLat,
          lat: lat,
          lon: lon,
        ));
        _lastUnsafeCurveTime = now;
        _unsafeCurveStart = null;
      }
    } else {
      _unsafeCurveStart = null;
    }

    // Overspeed
    if (_currentSpeedLimit != null && speedKmh > _currentSpeedLimit! + overspeedMargin) {
      _overspeedStart ??= now;
      final sustained = now.difference(_overspeedStart!) >= _overspeedMinDuration;
      final cooledDown = _lastOverspeedTime == null || now.difference(_lastOverspeedTime!) > _alertCooldown;
      if (sustained && cooledDown) {
        _triggerAlert(AlertEvent(
          timestamp: now,
          type: AlertType.overspeed,
          speed: speedKmh,
          lat: lat,
          lon: lon,
        ));
        _lastOverspeedTime = now;
        _overspeedStart = null;
      }
    } else {
      _overspeedStart = null;
    }
  }

  Future<void> _triggerAlert(AlertEvent event) async {
    _alertController.add(event);
    
    // Haptic feedback
    if (_hapticsEnabled && await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 200);
    }
    
    // Audio feedback (uses system alert sound; no asset required).
    if (_audioEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _alertController.close();
  }
}
