import 'connector_type_model.dart';
import 'package:client/core/utils/dio_client.dart';

class StationDetailModel {
  final int stationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? openingHours;
  final String? imageUrl;
  final double rating;
  final int totalReviews;
  final List<ConnectorTypeModel> connectorTypes;

  // ── Trạng thái check-in thời gian thực ──
  final String? crowdStatus;
  final String? statusUpdatedAt;
  final String? statusUpdatedByName;

  // ── Biểu đồ Popular Times (7 ngày x 24 giờ) ──
  final Map<String, List<int>>? popularTimes;

  StationDetailModel({
    required this.stationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.openingHours,
    this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.connectorTypes,
    this.crowdStatus,
    this.statusUpdatedAt,
    this.statusUpdatedByName,
    this.popularTimes,
  });

  factory StationDetailModel.fromJson(Map<String, dynamic> json) {
    var list = json['connectorTypes'] as List? ?? [];
    List<ConnectorTypeModel> connectors =
        list.map((i) => ConnectorTypeModel.fromJson(i)).toList();

    // Parse popularTimes: Map<String, List<int>>
    Map<String, List<int>>? popularTimes;
    if (json['popularTimes'] != null) {
      popularTimes = {};
      (json['popularTimes'] as Map<String, dynamic>).forEach((key, value) {
        popularTimes![key] = (value as List).map((v) => (v as num).toInt()).toList();
      });
    }

    return StationDetailModel(
      stationId: json['stationId'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openingHours: json['openingHours'],
      imageUrl: DioClient.sanitizeUrl(json['imageUrl']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      connectorTypes: connectors,
      crowdStatus: json['crowdStatus'],
      statusUpdatedAt: json['statusUpdatedAt'],
      statusUpdatedByName: json['statusUpdatedByName'],
      popularTimes: popularTimes,
    );
  }
}
