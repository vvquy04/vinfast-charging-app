import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'widgets/add_review_bottom_sheet.dart';
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


  void _showAddReviewBottomSheet(BuildContext context, int stationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddReviewBottomSheet(stationId: stationId),
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
                        itemBuilder: (context, index) => ReviewItemTile(review: reviewProvider.reviews[index]),
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
