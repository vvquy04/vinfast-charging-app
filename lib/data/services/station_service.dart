import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class StationService {
  final DioClient _dioClient;

  StationService(this._dioClient);

  /// GET /api/stations (hỗ trợ TOPSIS)
  Future<Response> searchStations({
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
    double? userLatitude,
    double? userLongitude,
  }) async {
    final Map<String, dynamic> queryParams = {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };

    if (userLatitude != null) {
      queryParams['userLatitude'] = userLatitude;
    }
    if (userLongitude != null) {
      queryParams['userLongitude'] = userLongitude;
    }
    
    if (connectorType != null && connectorType.isNotEmpty) {
      queryParams['connectorType'] = connectorType;
    }
    if (minPowerKw != null) {
      queryParams['minPowerKw'] = minPowerKw;
    }
    if (maxPowerKw != null) {
      queryParams['maxPowerKw'] = maxPowerKw;
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating;
    }

    // Tham số TOPSIS
    if (useTopsis) {
      queryParams['useTopsis'] = true;
      queryParams['weightDistance'] = weightDistance;
      queryParams['weightPower'] = weightPower;
      queryParams['weightOccupancy'] = weightOccupancy;
      queryParams['weightRating'] = weightRating;
    }

    return await _dioClient.dio.get('/api/stations', queryParameters: queryParams);
  }

  /// GET /api/stations/{stationId}
  Future<Response> getStationDetail(int stationId) async {
    return await _dioClient.dio.get('/api/stations/$stationId');
  }

  /// POST /api/stations/{stationId}/checkin
  Future<Response> checkinStation(int stationId, String status, {String? imageUrl}) async {
    final Map<String, dynamic> data = {'status': status};
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    return await _dioClient.dio.post(
      '/api/stations/$stationId/checkin',
      data: data,
    );
  }
}
