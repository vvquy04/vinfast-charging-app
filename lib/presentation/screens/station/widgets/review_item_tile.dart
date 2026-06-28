import 'package:flutter/material.dart';
import '../../../../data/models/review_model.dart';
import '../../../../core/constants/app_colors.dart';

class ReviewItemTile extends StatelessWidget {
  final ReviewModel review;
  final bool isMyReview;
  final VoidCallback? onDelete;

  const ReviewItemTile({
    super.key,
    required this.review,
    this.isMyReview = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.smoke,
          backgroundImage: review.avatarUrl != null ? NetworkImage(review.avatarUrl!) : null,
          child: review.avatarUrl == null ? const Icon(Icons.person, color: AppColors.gray) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(review.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (isMyReview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Bạn',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                        style: const TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                      if (isMyReview && onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: starIndex < review.rating ? Colors.amber : AppColors.smoke,
                  );
                }),
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.comment!, style: const TextStyle(fontSize: 14)),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
