import 'package:dio/dio.dart';
import '../models/station_summary_model.dart';
import '../models/station_detail_model.dart';
import '../models/review_model.dart';
import '../services/station_service.dart';

class StationRepository {
  final StationService _stationService;

  StationRepository(this._stationService);

  Future<List<StationSummaryModel>> searchStations({
    required double latitude,
    required double longitude,
    double radius = 10,
    String? connectorType,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _stationService.searchStations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        connectorType: connectorType,
        page: page,
        size: size,
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['content'] as List;
        return data.map((json) => StationSummaryModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch stations');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<StationDetailModel> getStationDetail(int stationId) async {
    try {
      final response = await _stationService.getStationDetail(stationId);
      if (response.statusCode == 200) {
        return StationDetailModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch station detail');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<ReviewModel>> getReviews(int stationId, {int page = 0, int size = 10}) async {
    try {
      final response = await _stationService.getReviews(stationId, page: page, size: size);
      if (response.statusCode == 200) {
        final data = response.data['data']['content'] as List;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch reviews');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> createReview(int stationId, {required int rating, String? comment}) async {
    try {
      final response = await _stationService.createReview(stationId, rating: rating, comment: comment);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to create review');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> deleteReview(int stationId, int reviewId) async {
    try {
      final response = await _stationService.deleteReview(stationId, reviewId);
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to delete review');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}
