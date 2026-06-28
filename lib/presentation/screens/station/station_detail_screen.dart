import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../providers/station_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import 'widgets/connector_type_card.dart';
import 'widgets/review_item_tile.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách đánh giá và ghi nhận lịch sử sau khi dựng giao diện xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = context.read<StationProvider>();
      final detail = stationProvider.selectedStationDetail;
      if (detail != null) {
        context.read<ReviewProvider>().fetchReviews(detail.stationId);
        context.read<HistoryProvider>().recordVisit(detail.stationId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final detail = provider.selectedStationDetail;
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final currentUser = authProvider.currentUser;

    if (detail == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin trạm sạc')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: detail.imageUrl != null
                  ? Image.network(
                      detail.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.smoke,
                        child: const Icon(Icons.charging_station_rounded, size: 80, color: AppColors.lightGray),
                      ),
                    )
                  : Container(
                      color: AppColors.smoke,
                      child: const Icon(Icons.charging_station_rounded, size: 80, color: AppColors.lightGray),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          detail.address,
                          style: const TextStyle(fontSize: 14, color: AppColors.gray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.gray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Giờ hoạt động: ${detail.openingHours ?? '24/7'}',
                          style: const TextStyle(fontSize: 14, color: AppColors.gray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating & Reviews
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${detail.rating.toStringAsFixed(1)} ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '(${detail.totalReviews} đánh giá)',
                        style: const TextStyle(color: AppColors.gray, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.xl),
                  const Text('Danh sách Trụ sạc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ...detail.connectorTypes.map((connector) => ConnectorTypeCard(connector: connector)),

                  const SizedBox(height: AppSizes.xl),
                  const Text('Đánh giá & Nhận xét', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.md),
                  
                  // Ô nhập đánh giá trực tiếp (Inline)
                  if (isAuthenticated)
                    _InlineReviewForm(stationId: detail.stationId)
                  else
                    const _LoginPromptCard(),

                  const SizedBox(height: AppSizes.xl),
                  
                  Consumer<ReviewProvider>(
                    builder: (context, reviewProvider, child) {
                      if (reviewProvider.isLoading && reviewProvider.reviews.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (reviewProvider.reviews.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.lg),
                            child: Text('Chưa có đánh giá nào. Hãy là người đầu tiên!', style: TextStyle(color: AppColors.gray)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviewProvider.reviews.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.smoke, height: 32),
                        itemBuilder: (context, index) {
                          final review = reviewProvider.reviews[index];
                          final isMyReview = currentUser != null && review.userId == currentUser.userId;
                          return ReviewItemTile(
                            review: review,
                            isMyReview: isMyReview,
                            onDelete: isMyReview
                                ? () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text(
                                          'Xóa đánh giá',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                                        ),
                                        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này không?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Hủy', style: TextStyle(color: AppColors.gray)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Xóa',
                                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await reviewProvider.deleteReview(review.reviewId);
                                    }
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineReviewForm extends StatefulWidget {
  final int stationId;

  const _InlineReviewForm({required this.stationId});

  @override
  State<_InlineReviewForm> createState() => _InlineReviewFormState();
}

class _InlineReviewFormState extends State<_InlineReviewForm> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final isLoading = reviewProvider.isLoading;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Viết đánh giá của bạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating.toInt();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _commentController,
            hint: 'Nhập trải nghiệm của bạn...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 100,
                height: 38,
                child: AppButton(
                  text: 'Gửi',
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () async {
                          final reviewProvider = context.read<ReviewProvider>();
                          final historyProvider = context.read<HistoryProvider>();
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final focusScope = FocusScope.of(context);

                          final success = await reviewProvider.submitReview(
                                widget.stationId,
                                _rating,
                                _commentController.text.trim(),
                              );
                          if (success && mounted) {
                            _commentController.clear();
                            focusScope.unfocus();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Đánh giá thành công!')),
                            );
                            try {
                              historyProvider.markAsReviewed(widget.stationId);
                            } catch (e) {
                              debugPrint('Error updating history: $e');
                            }
                          } else if (!success && mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(reviewProvider.errorMessage ?? 'Có lỗi xảy ra'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Đăng nhập để chia sẻ trải nghiệm của bạn về trạm sạc này.',
              style: TextStyle(fontSize: 13, color: AppColors.gray, height: 1.4),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login-options');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
