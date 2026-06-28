import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/upload_service.dart';

class UserRepository {
  final UserService _userService;
  final UploadService _uploadService;

  UserRepository(this._userService, this._uploadService);

  Future<UserModel> getMyProfile() async {
    try {
      final response = await _userService.getMyProfile();
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
      throw Exception('Không thể lấy thông tin hồ sơ');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<UserModel> updateMyProfile(Map<String, dynamic> data) async {
    try {
      final response = await _userService.updateMyProfile(data);
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Lỗi cập nhật hồ sơ');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<String> uploadAvatar(File file) async {
    try {
      return await _uploadService.uploadAvatar(file);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi upload ảnh');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Upload avatar từ bytes (dùng cho màn đăng ký khi dùng FilePicker).
  Future<String> uploadAvatarBytes(Uint8List bytes, String fileName) async {
    try {
      return await _uploadService.uploadAvatarBytes(bytes, fileName);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi upload ảnh');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
