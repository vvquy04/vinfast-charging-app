import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';
import '../models/user_model.dart';

/// Class containing raw API calls to backend endpoints.
class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  /// POST /api/auth/send-otp
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/send-otp',
        data: {'phoneNumber': phoneNumber},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// POST /api/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to verify OTP');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/login',
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/register',
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
          'fullName': fullName,
          'email': email,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }
}
