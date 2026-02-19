import 'package:dio/dio.dart';
import 'package:steermate/config/api_config.dart';
import 'package:steermate/services/storage_service.dart';
import 'dart:math' as math;

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static const int _maxRetries = 1;
  
  static void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.extra['retry_attempt'] ??= 0;
          return handler.next(options);
        },
        onError: (error, handler) async {
          // ignore: avoid_print
          print(
            'HTTP error: type=${error.type} method=${error.requestOptions.method} '
            'url=${error.requestOptions.uri} status=${error.response?.statusCode} '
            'data=${error.response?.data}',
          );

          // Handle auth invalidation.
          if (error.response?.statusCode == 401) {
            await StorageService.clearAll();
            return handler.next(error);
          }

          // Retry on transient failures.
          final requestOptions = error.requestOptions;
          final noRetry = requestOptions.extra['no_retry'] == true;
          if (noRetry) {
            return handler.next(error);
          }
          final attempt = (requestOptions.extra['retry_attempt'] as int?) ?? 0;
          final shouldRetry = _isTransient(error);
          if (shouldRetry && attempt < _maxRetries) {
            final nextAttempt = attempt + 1;
            requestOptions.extra['retry_attempt'] = nextAttempt;

            final backoffMs = 300 * math.pow(2, attempt).toInt();
            await Future.delayed(Duration(milliseconds: backoffMs));

            try {
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static bool _isTransient(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = error.response?.statusCode;
    if (status == null) return false;
    return status == 408 || status == 429 || (status >= 500 && status < 600);
  }
  
  static void init() {
    // Helpful when debugging emulator/phone connectivity.
    // `rawBaseUrl` comes from `--dart-define` (build-time), `baseUrl` is normalized.
    // ignore: avoid_print
    print('API configured: raw=${ApiConfig.rawBaseUrl} resolved=${ApiConfig.apiBaseUrl}');
    _setupInterceptors();
  }
  
  // Auth
  static Future<Response> register(String email, String password, String? name) async {
    return await _dio.post(
      ApiConfig.register,
      options: Options(extra: {'no_retry': true}),
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
  }
  
  static Future<Response> login(String email, String password) async {
    return await _dio.post(
      ApiConfig.login,
      options: Options(extra: {'no_retry': true}),
      data: {
        'email': email,
        'password': password,
      },
    );
  }
  
  // Trips
  static Future<Response> uploadTrip(Map<String, dynamic> tripData) async {
    return await _dio.post(
      ApiConfig.uploadTrip,
      data: tripData,
    );
  }
  
  static Future<Response> getTrips({int skip = 0, int limit = 100}) async {
    return await _dio.get(
      ApiConfig.getTrips,
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }
  
  static Future<Response> getTrip(int tripId) async {
    return await _dio.get('${ApiConfig.getTrip}/$tripId');
  }
  
  // Reports
  static Future<Response> getReport(int tripId) async {
    return await _dio.get('${ApiConfig.getReport}/$tripId');
  }
  
  static Future<Response> getTrends({int limit = 10}) async {
    return await _dio.get(
      ApiConfig.getTrends,
      queryParameters: {'limit': limit},
    );
  }
  
  // Profile
  static Future<Response> getProfile() async {
    return await _dio.get(ApiConfig.profile);
  }
}
