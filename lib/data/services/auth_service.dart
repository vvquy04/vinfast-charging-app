import 'dart:typed_data';

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

  /// POST /api/auth/oauth2/google
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/oauth2/google',
        data: {'idToken': idToken},
      );
      // Backend có thể trả về 200 OK (thành công) hoặc 202 Accepted (cần nhập sđt)
      return {
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Google login failed');
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

  /// POST /api/uploads/avatar
  Future<Map<String, dynamic>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        '/api/uploads/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Avatar upload failed');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// GET /api/users/me — Lấy thông tin cá nhân
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dioClient.dio.get('/api/users/me');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get profile');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// PUT /api/users/me — Cập nhật thông tin cá nhân
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put('/api/users/me', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
      } else {
        throw Exception('Network error or server unreachable');
      }
    }
  }

  /// PUT /api/users/me/password — Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/users/me/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
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
