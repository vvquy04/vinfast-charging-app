import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final UserRepository _repository;

  ProfileProvider(this._repository);

  UserModel? _profile;
  UserModel? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getMyProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.updateMyProfile(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadAvatar(File file) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _repository.uploadAvatar(file);
      // Ngay sau khi có URL, update profile luôn
      final success = await updateProfile({'avatarUrl': url});
      if (success) {
        return url;
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload avatar từ bytes (dùng cho màn đăng ký với FilePicker).
  /// Không gọi updateProfile vì user chưa đăng ký xong.
  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return await _repository.uploadAvatarBytes(bytes, fileName);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
