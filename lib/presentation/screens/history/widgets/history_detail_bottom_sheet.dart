import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../data/models/station_history_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';

class HistoryDetailBottomSheet extends StatefulWidget {
  final StationHistoryModel item;

  const HistoryDetailBottomSheet({
    super.key,
    required this.item,
  });

  @override
  State<HistoryDetailBottomSheet> createState() => _HistoryDetailBottomSheetState();
}

class _HistoryDetailBottomSheetState extends State<HistoryDetailBottomSheet> {
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchReviews(widget.item.stationId);
    });
  }

  Future<void> _navigateToStationDetailAndWrite() async {
    setState(() {
      _isLocalLoading = true;
    });
    final stationProvider = context.read<StationProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await stationProvider.fetchStationDetail(widget.item.stationId);
      if (mounted) {
        navigator.pop(); // Đóng bottom sheet lịch sử
        navigator.pushNamed('/station_detail'); // Chuyển hướng sang chi tiết trạm sạc
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Không thể tải chi tiết trạm sạc: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.userId;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Tiêu đề ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin lịch sử',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.gray),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Thẻ thông tin trạm sạc cơ bản ──────────────────────
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.item.stationImageUrl != null
                    ? Image.network(
                        widget.item.stationImageUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.stationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.stationAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          const Divider(color: AppColors.smoke, height: 1),
          const SizedBox(height: AppSizes.lg),

          // ─── Phần đánh giá của tôi ────────────────────────────
          const Text(
            'Đánh giá của bạn',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoal),
          ),
          const SizedBox(height: 8),
          Consumer<ReviewProvider>(
            builder: (context, reviewProvider, child) {
              if (reviewProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              // Tìm đánh giá của người dùng hiện tại
              ReviewModel? myReview;
              if (currentUserId != null) {
                try {
                  myReview = reviewProvider.reviews.firstWhere(
                    (r) => r.userId == currentUserId,
                  );
                  // Tự động đồng bộ trạng thái Đã bình luận nếu tìm thấy đánh giá
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<HistoryProvider>().markAsReviewed(widget.item.stationId);
                  });
                } catch (_) {
                  // Không tìm thấy đánh giá
                }
              }

              if (myReview != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.smoke),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingBarIndicator(
                            rating: myReview.rating.toDouble(),
                            itemBuilder: (context, index) => const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 18.0,
                          ),
                          Text(
                            '${myReview.createdAt.day}/${myReview.createdAt.month}/${myReview.createdAt.year}',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray),
                          ),
                        ],
                      ),
                      if (myReview.comment != null && myReview.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          myReview.comment!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.charcoal,
                            height: 1.4,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Đã đánh giá bằng số sao',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.smoke),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Bạn chưa viết đánh giá cho trạm sạc này.',
                      style: TextStyle(fontSize: 13, color: AppColors.gray),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLocalLoading ? null : _navigateToStationDetailAndWrite,
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Viết đánh giá ngay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSizes.xl),

          // ─── Nút xem chi tiết trạm sạc ──────────────────────────
          AppButton(
            text: 'Xem chi tiết trạm sạc',
            isLoading: _isLocalLoading,
            onPressed: _isLocalLoading ? null : _navigateToStationDetailAndWrite,
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.smoke,
      child: const Icon(
        Icons.charging_station_rounded,
        color: AppColors.lightGray,
        size: 32,
      ),
    );
  }
}
