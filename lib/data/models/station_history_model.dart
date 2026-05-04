class StationHistoryModel {
  final int historyId;
  final int stationId;
  final String stationName;
  final String stationAddress;
  final String? stationImageUrl;
  final int visitCount;
  final DateTime lastVisited;

  StationHistoryModel({
    required this.historyId,
    required this.stationId,
    required this.stationName,
    required this.stationAddress,
    this.stationImageUrl,
    required this.visitCount,
    required this.lastVisited,
  });

  factory StationHistoryModel.fromJson(Map<String, dynamic> json) {
    return StationHistoryModel(
      historyId: json['historyId'] ?? 0,
      stationId: json['stationId'] ?? 0,
      stationName: json['stationName'] ?? '',
      stationAddress: json['stationAddress'] ?? '',
      stationImageUrl: json['stationImageUrl'],
      visitCount: json['visitCount'] ?? 1,
      lastVisited: json['lastVisited'] != null
          ? DateTime.parse(json['lastVisited'])
          : DateTime.now(),
    );
  }
}
