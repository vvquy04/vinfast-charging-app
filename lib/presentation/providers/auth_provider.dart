import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Main state management class for Authentication.
/// Exposes currentUser and authorization status to the entire widget tree.
class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

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

  Future<void> logout() async {
    await _repository.removeToken();
    _currentUser = null;
    notifyListeners();
  }
}
