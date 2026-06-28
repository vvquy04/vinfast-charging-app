import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

/// Lớp thực hiện các cuộc gọi API xác thực đến backend.
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
        throw Exception(e.response?.data['message'] ?? 'Gửi OTP thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Xác thực OTP thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Đăng nhập thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Đăng ký thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Không thể kiểm tra email');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Đặt lại mật khẩu thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
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
        throw Exception(e.response?.data['message'] ?? 'Đổi mật khẩu thất bại');
      } else {
        throw Exception('Lỗi kết nối mạng hoặc server không phản hồi');
      }
    }
  }
}
