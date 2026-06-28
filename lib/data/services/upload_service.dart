import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/utils/dio_client.dart';

class UploadService {
  final DioClient _dioClient;

  UploadService(this._dioClient);

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String> uploadAvatar(File file) async {
    String fileName = file.path.split('/').last;
    String mimeType = _getMimeType(fileName);

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
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
    String mimeType = _getMimeType(fileName);

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
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
