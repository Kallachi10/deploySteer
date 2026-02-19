import 'package:flutter/foundation.dart';
import 'package:steermate/services/api_service.dart';

class TripProvider with ChangeNotifier {
  bool _isTripActive = false;
  List<Map<String, dynamic>> _trips = [];
  
  bool get isTripActive => _isTripActive;
  List<Map<String, dynamic>> get trips => _trips;
  
  void startTrip() {
    _isTripActive = true;
    notifyListeners();
  }
  
  void endTrip() {
    _isTripActive = false;
    notifyListeners();
  }
  
  Future<void> loadTrips() async {
    try {
      final response = await ApiService.getTrips();
      if (response.statusCode == 200) {
        _trips = List<Map<String, dynamic>>.from(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading trips: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getTrip(int tripId) async {
    try {
      final response = await ApiService.getTrip(tripId);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error getting trip: $e');
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getReport(int tripId) async {
    try {
      final response = await ApiService.getReport(tripId);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error getting report: $e');
    }
    return null;
  }
}
