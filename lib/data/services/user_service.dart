import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class UserService {
  final DioClient _dioClient;

  UserService(this._dioClient);

  Future<Response> getMyProfile() async {
    return await _dioClient.dio.get('/api/users/me');
  }

  Future<Response> updateMyProfile(Map<String, dynamic> data) async {
    return await _dioClient.dio.put(
      '/api/users/me',
      data: data,
    );
  }
}
