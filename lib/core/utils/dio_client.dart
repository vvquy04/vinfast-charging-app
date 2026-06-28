import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Cấu hình Dio Client dùng chung cho toàn bộ ứng dụng.
/// Tự động đính kèm JWT token vào header của mỗi request.
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

    // Interceptor tự động đính kèm JWT token vào request
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
          return handler.next(e);
        },
          
      ),
    );
  }

  static String? sanitizeUrl(String? url) {
    if (url == null) return null;
    if (!kIsWeb) {
      try {
        if (url.startsWith('http://localhost:8080') || url.startsWith('http://127.0.0.1:8080')) {
          return url
              .replaceAll('http://localhost:8080', baseUrl)
              .replaceAll('http://127.0.0.1:8080', baseUrl);
        }
        if (url.startsWith('https://localhost:8080') || url.startsWith('https://127.0.0.1:8080')) {
          return url
              .replaceAll('https://localhost:8080', baseUrl)
              .replaceAll('https://127.0.0.1:8080', baseUrl);
        }
        final Uri baseUri = Uri.parse(baseUrl);
        final String hostPort = (baseUri.port == 80 || baseUri.port == 443 || baseUri.port == 0)
            ? baseUri.host
            : "${baseUri.host}:${baseUri.port}";
        
        String sanitized = url
            .replaceAll('localhost:8080', hostPort)
            .replaceAll('127.0.0.1:8080', hostPort);
            
        if (baseUrl.startsWith('https://') && sanitized.startsWith('http://')) {
          sanitized = sanitized.replaceFirst('http://', 'https://');
        }
        return sanitized;
      } catch (_) {
        return url;
      }
    }
    return url;
  }
}
