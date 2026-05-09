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
    double? minRating,
    int page = 0,
    int size = 20,
  }) async {
    final Map<String, dynamic> queryParams = {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'page': page,
      'size': size,
    };
    
    if (connectorType != null && connectorType.isNotEmpty) {
      queryParams['connectorType'] = connectorType;
    }
    if (minPowerKw != null) {
      queryParams['minPowerKw'] = minPowerKw;
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
