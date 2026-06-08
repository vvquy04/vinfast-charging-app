import 'connector_type_model.dart';
import 'package:client/core/utils/dio_client.dart';

class StationSummaryModel {
  final int stationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? openingHours;
  final String? imageUrl;
  final double rating;
  final int totalReviews;
  final double distance;
  final List<ConnectorTypeModel> connectorTypes;

  StationSummaryModel({
    required this.stationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.openingHours,
    this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.distance,
    required this.connectorTypes,
  });

  factory StationSummaryModel.fromJson(Map<String, dynamic> json) {
    var list = json['connectorTypes'] as List? ?? [];
    List<ConnectorTypeModel> connectors =
        list.map((i) => ConnectorTypeModel.fromJson(i)).toList();

    return StationSummaryModel(
      stationId: json['stationId'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openingHours: json['openingHours'],
      imageUrl: DioClient.sanitizeUrl(json['imageUrl']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      distance: (json['distance'] ?? 0.0).toDouble(),
      connectorTypes: connectors,
    );
  }
}
