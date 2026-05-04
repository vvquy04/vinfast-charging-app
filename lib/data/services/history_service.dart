import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class HistoryService {
  final DioClient _dioClient;

  HistoryService(this._dioClient);

  Future<Response> getHistory(int page, int size) async {
    return await _dioClient.dio.get(
      '/api/history',
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<Response> recordVisit(int stationId) async {
    return await _dioClient.dio.post('/api/history/$stationId');
  }

  Future<Response> deleteHistory(int historyId) async {
    return await _dioClient.dio.delete('/api/history/$historyId');
  }
}
