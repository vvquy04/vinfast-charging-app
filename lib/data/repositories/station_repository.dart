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
    int? maxPowerKw,
    double? minRating,
    bool useTopsis = false,
    double weightDistance = 1.0,
    double weightPower = 1.0,
    double weightOccupancy = 1.0,
    double weightRating = 1.0,
  }) async {
    try {
      final response = await _stationService.searchStations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        connectorType: connectorType,
        minPowerKw: minPowerKw,
        maxPowerKw: maxPowerKw,
        minRating: minRating,
        useTopsis: useTopsis,
        weightDistance: weightDistance,
        weightPower: weightPower,
        weightOccupancy: weightOccupancy,
        weightRating: weightRating,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
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

  /// Check-in tại trạm sạc và báo cáo trạng thái
  Future<String> checkinStation(int stationId, String status, {String? imageUrl}) async {
    try {
      final response = await _stationService.checkinStation(stationId, status, imageUrl: imageUrl);
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Check-in thành công!';
      }
      throw Exception(response.data['message'] ?? 'Check-in thất bại');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}
