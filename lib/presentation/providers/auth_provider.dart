import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Main state management class for Authentication.
/// Exposes currentUser and authorization status to the entire widget tree.
class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    // Optionally check if token exists to automatically restore session on app launch
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.sendOtp(phoneNumber);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool?> verifyOtp(String phoneNumber, String otp) async {
    _setLoading(true);
    _setError(null);
    try {
      final isNewUser = await _repository.verifyOtp(phoneNumber, otp);
      _setLoading(false);
      return isNewUser;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<bool> login(String phoneNumber, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _repository.login(phoneNumber, password);
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({
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
    _setLoading(true);
    _setError(null);
    try {
      final user = await _repository.register(
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
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return await _repository.uploadAvatar(bytes: bytes, fileName: fileName);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  /// Xử lý đăng nhập Google
  /// Trả về Map chứa thông tin xử lý tiếp theo, hoặc null nếu lỗi/huỷ
  Future<Map<String, dynamic>?> handleGoogleSignIn() async {
    _setLoading(true);
    _setError(null);
    try {
      // Đăng xuất trước để đảm bảo chọn tài khoản mới
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Không thể lấy ID token từ Google');
      }

      final result = await _repository.loginWithGoogle(idToken);
      
      if (result['isNewUser'] == false) {
        _currentUser = result['user'];
        notifyListeners();
      }
      
      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.removeToken();
    _currentUser = null;
    notifyListeners();
  }

  /// Tải thông tin profile từ server (GET /api/users/me)
  Future<bool> loadProfile() async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _repository.getProfile();
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Cập nhật thông tin profile (PUT /api/users/me)
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _repository.updateProfile(data);
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}
