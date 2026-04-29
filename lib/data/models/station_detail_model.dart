import 'connector_type_model.dart';

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
  });

  factory StationDetailModel.fromJson(Map<String, dynamic> json) {
    var list = json['connectorTypes'] as List? ?? [];
    List<ConnectorTypeModel> connectors =
        list.map((i) => ConnectorTypeModel.fromJson(i)).toList();

    return StationDetailModel(
      stationId: json['stationId'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      openingHours: json['openingHours'],
      imageUrl: json['imageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      connectorTypes: connectors,
    );
  }
}
