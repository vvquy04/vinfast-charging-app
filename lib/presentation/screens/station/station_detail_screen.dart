import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../providers/station_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch reviews and record history after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = context.read<StationProvider>();
      final detail = stationProvider.selectedStationDetail;
      if (detail != null) {
        context.read<ReviewProvider>().fetchReviews(detail.stationId);
        context.read<HistoryProvider>().recordVisit(detail.stationId);
      }
    });
  }


  void _showAddReviewBottomSheet(BuildContext context, int stationId) {
    int _rating = 5;
    final _commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                      onPressed: () => Navigator.pop(ctx),
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
                      _rating = rating.toInt();
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
                          stationId,
                          _rating,
                          _commentController.text.trim(),
                        );
                        if (success && ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đánh giá thành công!')),
                          );
                        } else if (!success && ctx.mounted) {
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
      },
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yêu cầu Đăng nhập',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        content: const Text(
          'Bạn cần đăng nhập tài khoản để viết nhận xét và đánh giá cho trạm sạc này.',
          style: TextStyle(color: AppColors.gray, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login-options');
            },
            child: const Text(
              'Đăng nhập',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final detail = provider.selectedStationDetail;

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
                  ? Image.network(detail.imageUrl!, fit: BoxFit.cover)
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
                  const SizedBox(height: AppSizes.md),
                  ...detail.connectorTypes.map((connector) {
                    bool available = connector.totalPorts > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.silver),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.smoke,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.electrical_services_rounded, color: AppColors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connector.type,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Công suất: ${connector.powerKw} kW',
                                  style: const TextStyle(fontSize: 13, color: AppColors.gray),
                                )
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: available ? AppColors.primary.withOpacity(0.1) : AppColors.lightGray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${connector.totalPorts} trống',
                              style: TextStyle(
                                  color: available ? AppColors.primary : AppColors.gray,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: AppSizes.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đánh giá & Nhận xét', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () {
                          final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
                          if (isAuthenticated) {
                            _showAddReviewBottomSheet(context, detail.stationId);
                          } else {
                            _showLoginRequiredDialog(context);
                          }
                        },
                        child: const Text('Viết đánh giá', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
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
