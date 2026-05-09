import 'package:dio/dio.dart';
import '../models/station_summary_model.dart';
import '../models/station_detail_model.dart';
import '../services/station_service.dart';

class StationRepository {
  final StationService _stationService;

  StationRepository(this._stationService);

  Future<List<StationSummaryModel>> searchStations({
    required double latitude,
    required double longitude,
    double radius = 10,
    String? connectorType,
    int? minPowerKw,
    double? minRating,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _stationService.searchStations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        connectorType: connectorType,
        minPowerKw: minPowerKw,
        minRating: minRating,
        page: page,
        size: size,
      );

      if (response.statusCode == 200) {
        // ApiResponse<PageResponse<StationSummaryResponse>>
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
}
