import 'package:flutter/material.dart';
import '../../../../data/models/review_model.dart';
import '../../../../core/constants/app_colors.dart';

class ReviewItemTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewItemTile({
    super.key,
    required this.review,
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
                  Text(review.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                    style: const TextStyle(color: AppColors.gray, fontSize: 12),
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
