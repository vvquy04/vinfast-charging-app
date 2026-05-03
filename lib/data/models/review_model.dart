class ReviewModel {
  final int reviewId;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? 'User',
      userAvatarUrl: json['userAvatarUrl'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }
}
