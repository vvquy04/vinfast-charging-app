class ReviewModel {
  final int reviewId;
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final int stationId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.stationId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
      stationId: json['stationId'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
