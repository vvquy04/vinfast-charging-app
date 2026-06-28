import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final int stationId;

  const AddReviewBottomSheet({
    super.key,
    required this.stationId,
  });

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Viết Đánh Giá',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Center(
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating.toInt();
                  });
                },
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            AppTextField(
              controller: _commentController,
              hint: 'Nhập trải nghiệm của bạn (tùy chọn)...',
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.xl),
            Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                return AppButton(
                  text: 'Gửi Đánh Giá',
                  isLoading: reviewProvider.isLoading,
                  onPressed: () async {
                    final success = await reviewProvider.submitReview(
                      widget.stationId,
                      _rating,
                      _commentController.text.trim(),
                    );
                    if (success && context.mounted) {
                      try {
                        context.read<HistoryProvider>().markAsReviewed(widget.stationId);
                      } catch (e) {
                        debugPrint('Lỗi cập nhật lịch sử đánh giá: $e');
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đánh giá thành công!')),
                      );
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(reviewProvider.errorMessage ?? 'Có lỗi xảy ra'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
