import 'package:dio/dio.dart';
import '../models/station_history_model.dart';
import '../services/history_service.dart';

class HistoryRepository {
  final HistoryService _service;

  HistoryRepository(this._service);

  Future<List<StationHistoryModel>> getHistory({int page = 0, int size = 20}) async {
    try {
      final response = await _service.getHistory(page, size);
      if (response.data['success'] == true) {
        final List<dynamic> content = response.data['data']['content'];
        return content.map((json) => StationHistoryModel.fromJson(json)).toList();
      }
      throw Exception('Không lấy được danh sách lịch sử');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> recordVisit(int stationId) async {
    try {
      final response = await _service.recordVisit(stationId);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Lỗi ghi nhận lịch sử');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> deleteHistory(int historyId) async {
    try {
      final response = await _service.deleteHistory(historyId);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Lỗi xóa lịch sử');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
