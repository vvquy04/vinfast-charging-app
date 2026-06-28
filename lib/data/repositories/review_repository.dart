import 'package:dio/dio.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewRepository {
  final ReviewService _service;

  ReviewRepository(this._service);

  Future<List<ReviewModel>> getReviewsByStation(int stationId) async {
    try {
      final response = await _service.getReviewsByStation(stationId);
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => ReviewModel.fromJson(json)).toList();
      }
      throw Exception('Không lấy được danh sách đánh giá');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<ReviewModel> submitReview(int stationId, int rating, String? comment) async {
    try {
      final response = await _service.submitReview(stationId, rating, comment);
      if (response.data['success'] == true) {
        return ReviewModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Lỗi gửi đánh giá');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> deleteReview(int reviewId) async {
    try {
      final response = await _service.deleteReview(reviewId);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Lỗi xóa đánh giá');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
