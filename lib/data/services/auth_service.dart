import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

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
        data: {'phoneNumber': phoneNumber, 'otp': otp},
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
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/login',
        data: {'phoneNumber': phoneNumber, 'password': password},
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
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
    String? vehicleModel,
    String? connectorType,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/register',
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
          'fullName': fullName,
          'email': email,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
          'avatarUrl': avatarUrl,
          'vehicleModel': vehicleModel,
          'connectorType': connectorType,
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

  /// GET /api/auth/check-email
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/auth/check-email',
        queryParameters: {'email': email},
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        return data['data']['exists'] == true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to check email');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// POST /api/auth/reset-password
  Future<Map<String, dynamic>> resetPassword(
    String phoneNumber,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/reset-password',
        data: {
          'phoneNumber': phoneNumber,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to reset password');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// PUT /api/users/me/change-password
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/users/me/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to change password');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }
}
