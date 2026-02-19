import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _hardBrakeThresholdKey = 'hardBrakeThreshold';
  static const String _harshAccelThresholdKey = 'harshAccelThreshold';
  static const String _curveThresholdKey = 'curveThreshold';
  static const String _overspeedMarginKey = 'overspeedMargin';
  static const String _hapticsEnabledKey = 'hapticsEnabled';
  static const String _audioEnabledKey = 'audioEnabled';

  static Future<double> getHardBrakeThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_hardBrakeThresholdKey) ?? 4.0; // m/s²
  }

  static Future<void> setHardBrakeThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_hardBrakeThresholdKey, value);
  }

  static Future<double> getHarshAccelThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_harshAccelThresholdKey) ?? 4.0; // m/s²
  }

  static Future<void> setHarshAccelThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_harshAccelThresholdKey, value);
  }

  static Future<double> getCurveThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_curveThresholdKey) ?? 2.5; // m/s²
  }

  static Future<void> setCurveThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_curveThresholdKey, value);
  }

  static Future<double> getOverspeedMargin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_overspeedMarginKey) ?? 5.0; // km/h
  }

  static Future<void> setOverspeedMargin(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_overspeedMarginKey, value);
  }

  static Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsEnabledKey) ?? true;
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, enabled);
  }

  static Future<bool> getAudioEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_audioEnabledKey) ?? false;
  }

  static Future<void> setAudioEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioEnabledKey, enabled);
  }
}