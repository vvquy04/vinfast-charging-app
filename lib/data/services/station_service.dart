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

    return await _dioClient.dio.get('/api/stations', queryParameters: queryParams);
  }

  /// GET /api/stations/{stationId}
  Future<Response> getStationDetail(int stationId) async {
    return await _dioClient.dio.get('/api/stations/$stationId');
  }

  /// GET /api/stations/{stationId}/reviews?page=0&size=10
  Future<Response> getReviews(int stationId, {int page = 0, int size = 10}) async {
    return await _dioClient.dio.get(
      '/api/stations/$stationId/reviews',
      queryParameters: {'page': page, 'size': size},
    );
  }

  /// POST /api/stations/{stationId}/reviews
  Future<Response> createReview(int stationId, {required int rating, String? comment}) async {
    return await _dioClient.dio.post(
      '/api/stations/$stationId/reviews',
      data: {
        'rating': rating,
        'comment': comment,
      },
    );
  }

  /// DELETE /api/stations/{stationId}/reviews/{reviewId}
  Future<Response> deleteReview(int stationId, int reviewId) async {
    return await _dioClient.dio.delete('/api/stations/$stationId/reviews/$reviewId');
  }
}
