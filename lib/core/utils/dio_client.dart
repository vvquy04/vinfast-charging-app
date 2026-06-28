import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Centralized Dio client for the application.
/// Provides configuration and interceptors to automatically inject JWT tokens.
class DioClient {
  // Sử dụng localhost cho Web, URL ngrok cho máy thật Android
  static const String baseUrl = kIsWeb ? 'http://localhost:8080' : 'https://shimmer-itinerary-spilt.ngrok-free.dev';

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

  static String? sanitizeUrl(String? url) {
    if (url == null) return null;
    if (!kIsWeb) {
      try {
        final Uri baseUri = Uri.parse(baseUrl);
        final String hostPort = "${baseUri.host}:${baseUri.port}";
        return url
            .replaceAll('localhost:8080', hostPort)
            .replaceAll('127.0.0.1:8080', hostPort);
      } catch (_) {
        return url;
      }
    }
    return url;
  }
}
