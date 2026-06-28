import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Bridge between state management and raw services.
/// Also stores tokens and configurations persistent within SharedPreferences.
class AuthRepository {
  final AuthService _authService;
  static const String _tokenKey = 'access_token';

  AuthRepository(this._authService);

  Future<String> sendOtp(String phoneNumber) async {
    final response = await _authService.sendOtp(phoneNumber);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to send OTP');
    }
    return response['data']?['otp'] as String? ?? '';
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
}
