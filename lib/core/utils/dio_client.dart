import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Centralized Dio client for the application.
/// Provides configuration and interceptors to automatically inject JWT tokens.
class DioClient {
  // Sử dụng localhost cho Web, IP local cho máy thật Android (chung Wi-Fi)
  static const String baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://192.168.1.7:8080';

  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
      ),
    );

    // Request interceptor to attach JWT token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // TODO: Intercept 401 Unauthorized for token refresh logic
          return handler.next(e);
        },
      ),
    );
  }
}
