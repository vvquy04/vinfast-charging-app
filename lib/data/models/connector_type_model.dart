class ConnectorTypeModel {
  final String type;
  final int powerKw;
  final int totalPorts;

  ConnectorTypeModel({
    required this.type,
    required this.powerKw,
    required this.totalPorts,
  });

  factory ConnectorTypeModel.fromJson(Map<String, dynamic> json) {
    return ConnectorTypeModel(
      type: json['type'] ?? '',
      powerKw: json['powerKw'] ?? 0,
      totalPorts: json['totalPorts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'powerKw': powerKw,
      'totalPorts': totalPorts,
    };
  }
}
