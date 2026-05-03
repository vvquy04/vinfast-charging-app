import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Bridge between state management and raw services.
/// Also stores tokens and configurations persistent within SharedPreferences.
class AuthRepository {
  final AuthService _authService;
  static const String _tokenKey = 'access_token';

  AuthRepository(this._authService);

  Future<void> sendOtp(String phoneNumber) async {
    final response = await _authService.sendOtp(phoneNumber);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to send OTP');
    }
  }

  /// Returns true if it's a new user, false otherwise.
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    final response = await _authService.verifyOtp(phoneNumber, otp);
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      // Jackson in Spring Boot converts 'boolean isNewUser' to 'newUser' in JSON mapping automatically!
      return data['isNewUser'] == true || data['newUser'] == true;
    } else {
      throw Exception(response['message'] ?? 'Failed to verify OTP');
    }
  }

  Future<UserModel> login(String phoneNumber, String password) async {
    final response = await _authService.login(phoneNumber, password);

    // Parse the standardized response: { "success": true, "data": { ...AuthResponse fields..., "token": "..." } }
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final token = data['token'] as String;

      // Save token locally
      await saveToken(token);

      return UserModel.fromJson(Map<String, dynamic>.from(data));
    } else {
      throw Exception(response['message'] ?? 'Unexpected login failure');
    }
  }

  /// Gọi API loginWithGoogle
  /// Trả về một Map chứa:
  /// - 'isNewUser': true/false
  /// - 'user': UserModel (nếu isNewUser = false)
  /// - 'googleData': Map chứa email, name, avatarUrl (nếu isNewUser = true)
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _authService.loginWithGoogle(idToken);
    final statusCode = response['statusCode'];
    final body = response['data'];

    if (statusCode == 200 && body['success'] == true && body['data'] != null) {
      // Đăng nhập thành công, đã có tài khoản
      final data = body['data'];
      final token = data['token'] as String;
      await saveToken(token);
      return {
        'isNewUser': false,
        'user': UserModel.fromJson(Map<String, dynamic>.from(data)),
      };
    } else if (statusCode == 202 && body['success'] == true && body['data'] != null) {
      // Chưa có tài khoản, yêu cầu SĐT
      return {
        'isNewUser': true,
        'googleData': body['data'],
      };
    } else {
      throw Exception(body['message'] ?? 'Google login failed');
    }
  }

  Future<UserModel> register({
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
    final response = await _authService.register(
      phoneNumber: phoneNumber,
      password: password,
      fullName: fullName,
      email: email,
      gender: gender,
      dateOfBirth: dateOfBirth,
      avatarUrl: avatarUrl,
      vehicleModel: vehicleModel,
      connectorType: connectorType,
    );

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final token = data['token'] as String;

      await saveToken(token);

      return UserModel.fromJson(Map<String, dynamic>.from(data));
    } else {
      throw Exception(response['message'] ?? 'Unexpected registration failure');
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await _authService.uploadAvatar(
      bytes: bytes,
      fileName: fileName,
    );

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return data['url'] as String;
    }

    throw Exception(response['message'] ?? 'Unexpected avatar upload failure');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  /// GET /api/users/me — Tải thông tin profile
  Future<UserModel> getProfile() async {
    final response = await _authService.getProfile();
    if (response['success'] == true && response['data'] != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    throw Exception(response['message'] ?? 'Failed to load profile');
  }

  /// PUT /api/users/me — Cập nhật thông tin profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _authService.updateProfile(data);
    if (response['success'] == true && response['data'] != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(response['data']));
    }
    throw Exception(response['message'] ?? 'Failed to update profile');
  }
}
