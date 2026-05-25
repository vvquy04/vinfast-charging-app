import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class UploadService {
  final DioClient _dioClient;

  UploadService(this._dioClient);

  Future<String> uploadAvatar(File file) async {
    String fileName = file.path.split('/').last;

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dioClient.dio.post(
      '/api/uploads/avatar',
      data: formData,
    );

    if (response.data['success'] == true) {
      return response.data['data']['url'];
    } else {
      throw Exception(response.data['message'] ?? 'Lỗi tải ảnh lên');
    }
  }

  /// Upload avatar từ bytes (dùng cho FilePicker khi chưa có File object).
  Future<String> uploadAvatarBytes(Uint8List bytes, String fileName) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dioClient.dio.post(
      '/api/uploads/avatar',
      data: formData,
    );

    if (response.data['success'] == true) {
      return response.data['data']['url'];
    } else {
      throw Exception(response.data['message'] ?? 'Lỗi tải ảnh lên');
    }
  }
}
