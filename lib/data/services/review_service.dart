import 'package:dio/dio.dart';
import '../../core/utils/dio_client.dart';

class ReviewService {
  final DioClient _dioClient;

  ReviewService(this._dioClient);

  Future<Response> getReviewsByStation(int stationId, int page, int size) async {
    return await _dioClient.dio.get(
      '/api/reviews/station/$stationId',
      queryParameters: {'page': page, 'size': size},
    );
  }

  Future<Response> submitReview(int stationId, int rating, String? comment) async {
    return await _dioClient.dio.post(
      '/api/reviews',
      data: {
        'stationId': stationId,
        'rating': rating,
        'comment': comment,
      },
    );
  }

  Future<Response> deleteReview(int reviewId) async {
    return await _dioClient.dio.delete('/api/reviews/$reviewId');
  }
}
