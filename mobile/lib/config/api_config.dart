class ApiConfig {
  // Update this to your backend URL
  // For Android emulator: http://10.0.2.2:8000
  // For iOS simulator: http://localhost:8000
  // For physical device: http://YOUR_COMPUTER_IP:8000
  // Prefer `--dart-define=API_BASE_URL=http://...:8000` for development.
  /// Raw value provided by `--dart-define=API_BASE_URL=...`.
  ///
  /// Note: `String.fromEnvironment` is evaluated at build time. If you change
  /// the value, do a full restart / rebuild (hot reload won't update it).
  static const String rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Normalized backend origin, always includes scheme and no trailing slash.
  ///
  /// Accepts values like:
  /// - `http://10.0.2.2:8000`
  /// - `10.0.2.2:8000` (will be treated as http)
  static String get baseUrl {
    var value = rawBaseUrl.trim();
    if (value.isEmpty) {
      value = 'http://10.0.2.2:8000';
    }
    if (!value.contains('://')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
  static const String apiVersion = '/api/v1';
  
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/users/profile';
  static const String uploadTrip = '/trips/upload';
  static const String getTrips = '/trips';
  static const String getTrip = '/trips';
  static const String getReport = '/reports';
  static const String getTrends = '/reports/analytics/trends';
}
