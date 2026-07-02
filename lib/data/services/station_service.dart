import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class StationService {
  final DioClient _dioClient;

  StationService(this._dioClient);

  /// GET /api/stations
  Future<Response> searchStations({
    required double latitude,
    required double longitude,
    double radius = 10,
    String? connectorType,
    int? minPowerKw,
    int? maxPowerKw,
    double? minRating,
  }) async {
    final Map<String, dynamic> queryParams = {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
    
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

    return await _dioClient.dio.get('/api/stations', queryParameters: queryParams);
  }

  /// GET /api/stations/{stationId}
  Future<Response> getStationDetail(int stationId) async {
    return await _dioClient.dio.get('/api/stations/$stationId');
  }
}
