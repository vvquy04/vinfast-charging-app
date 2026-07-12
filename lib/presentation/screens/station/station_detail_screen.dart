import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/station_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../data/models/station_detail_model.dart';
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
  String _selectedDay = 'Thứ 2';

  @override
  void initState() {
    super.initState();
    final dayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    _selectedDay = days[dayOfWeek - 1];

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

                  const SizedBox(height: 16),

                  // Check-in & Báo cáo trạng thái thực tế
                  _buildCheckinWidget(context, provider, isAuthenticated, detail),

                  const SizedBox(height: AppSizes.xl),
                  const Text('Danh sách Trụ sạc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ...detail.connectorTypes.map((connector) => ConnectorTypeCard(connector: connector)),

                  // Biểu đồ Popular Times bận rộn lịch sử
                  if (detail.popularTimes != null) ...[
                    const SizedBox(height: AppSizes.xl),
                    _buildPopularTimesChart(detail.popularTimes!),
                  ],

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

  Widget _buildCheckinWidget(
      BuildContext context, StationProvider provider, bool isAuthenticated, StationDetailModel detail) {
    final status = detail.crowdStatus;
    final hasReport = detail.statusUpdatedAt != null;

    String statusText = 'Chưa có check-in';
    Color color = AppColors.gray;
    Color bgColor = AppColors.smoke;
    IconData icon = Icons.info_outline_rounded;

    if (status != null) {
      switch (status) {
        case 'EMPTY':
          statusText = 'Trống chỗ';
          color = const Color(0xFF2E7D32);
          bgColor = const Color(0xFFE8F5E9);
          icon = Icons.check_circle_outline_rounded;
          break;
        case 'MODERATE':
          statusText = 'Bình thường';
          color = const Color(0xFFF57C00);
          bgColor = const Color(0xFFFFF3E0);
          icon = Icons.hourglass_empty_rounded;
          break;
        case 'BUSY':
          statusText = 'Đông đúc';
          color = const Color(0xFFD32F2F);
          bgColor = const Color(0xFFFFEBEE);
          icon = Icons.error_outline_rounded;
          break;
        case 'MAINTENANCE':
          statusText = 'Đang bảo trì';
          color = const Color(0xFFC2185B);
          bgColor = const Color(0xFFFCE4EC);
          icon = Icons.build_outlined;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái thực tế: $statusText',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasReport
                          ? 'Cập nhật bởi ${detail.statusUpdatedByName} (${detail.statusUpdatedAt})'
                          : 'Hãy là người đầu tiên check-in tại đây!',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !isAuthenticated
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để checkin!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      )
                  : () => _showCheckinDialog(context, provider, detail),
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text(
                'Check-in',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color == AppColors.gray ? AppColors.primary : color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'EMPTY': return Icons.check_circle_rounded;
      case 'MODERATE': return Icons.info_rounded;
      case 'BUSY': return Icons.remove_circle_rounded;
      case 'MAINTENANCE': return Icons.build_rounded;
      default: return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'EMPTY': return const Color(0xFF2E7D32);
      case 'MODERATE': return const Color(0xFFF57C00);
      case 'BUSY': return const Color(0xFFD32F2F);
      case 'MAINTENANCE': return const Color(0xFF757575);
      default: return Colors.black;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'EMPTY': return 'Trống chỗ';
      case 'MODERATE': return 'Bình thường';
      case 'BUSY': return 'Đông đúc';
      case 'MAINTENANCE': return 'Đang bảo trì';
      default: return status;
    }
  }

  void _showCheckinDialog(BuildContext context, StationProvider provider, StationDetailModel detail) {
    String? selectedStatus;
    File? pickedFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final isFormReady = selectedStatus != null && pickedFile != null;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              title: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Check-in',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.gray, size: 22),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFormReady) ...[
                      _buildCheckinSelectionButton(
                        dialogContext,
                        'EMPTY',
                        Icons.check_circle_rounded,
                        const Color(0xFF2E7D32),
                        'Trống chỗ',
                        (status) async {
                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 60,
                              maxWidth: 1024,
                            );
                            if (pickedImage != null) {
                              setState(() {
                                selectedStatus = status;
                                pickedFile = File(pickedImage.path);
                              });
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chụp ảnh hiện trạng để xác thực check-in!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Lỗi chụp ảnh: $e');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCheckinSelectionButton(
                        dialogContext,
                        'MODERATE',
                        Icons.info_rounded,
                        const Color(0xFFF57C00),
                        'Bình thường',
                        (status) async {
                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 60,
                              maxWidth: 1024,
                            );
                            if (pickedImage != null) {
                              setState(() {
                                selectedStatus = status;
                                pickedFile = File(pickedImage.path);
                              });
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chụp ảnh hiện trạng để xác thực check-in!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Lỗi chụp ảnh: $e');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCheckinSelectionButton(
                        dialogContext,
                        'BUSY',
                        Icons.remove_circle_rounded,
                        const Color(0xFFD32F2F),
                        'Đông đúc',
                        (status) async {
                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 60,
                              maxWidth: 1024,
                            );
                            if (pickedImage != null) {
                              setState(() {
                                selectedStatus = status;
                                pickedFile = File(pickedImage.path);
                              });
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chụp ảnh hiện trạng để xác thực check-in!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Lỗi chụp ảnh: $e');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCheckinSelectionButton(
                        dialogContext,
                        'MAINTENANCE',
                        Icons.build_rounded,
                        const Color(0xFF757575),
                        'Đang bảo trì',
                        (status) async {
                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 60,
                              maxWidth: 1024,
                            );
                            if (pickedImage != null) {
                              setState(() {
                                selectedStatus = status;
                                pickedFile = File(pickedImage.path);
                              });
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chụp ảnh hiện trạng để xác thực check-in!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Lỗi chụp ảnh: $e');
                          }
                        },
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          pickedFile!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(selectedStatus!).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(selectedStatus!).withOpacity(0.3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getStatusIcon(selectedStatus!), color: _getStatusColor(selectedStatus!), size: 22),
                            const SizedBox(width: 12),
                            Text(
                              _getStatusLabel(selectedStatus!),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: _getStatusColor(selectedStatus!),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _submitCheckin(context, provider, detail, selectedStatus!, pickedFile!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedStatus = null;
                              pickedFile = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.smoke, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Huỷ',
                            style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckinSelectionButton(
    BuildContext ctx,
    String status,
    IconData icon,
    Color iconColor,
    String labelText,
    Function(String) onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: const BorderSide(color: AppColors.smoke, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => onTap(status),
        icon: Icon(icon, color: iconColor, size: 22),
        label: Text(
          labelText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _submitCheckin(
    BuildContext context,
    StationProvider provider,
    StationDetailModel detail,
    String status,
    File imageFile,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Đang upload ảnh và gửi check-in...'),
          ],
        ),
        duration: Duration(days: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await provider.checkinStation(detail.stationId, status, imageFile: imageFile);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      try {
        context.read<ProfileProvider>().fetchProfile();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.checkinMessage ?? 'Đã gửi!'),
          backgroundColor: success ? const Color(0xFF43A047) : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildPopularTimesChart(Map<String, List<int>> popularTimes) {
    final busyList = popularTimes[_selectedDay] ?? List.filled(24, 0);
    final now = DateTime.now();
    final currentHour = now.hour;
    final todayWeekday = now.weekday; // 1 = Thứ 2, 7 = Chủ nhật
    final days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    final selectedDayIndex = days.indexOf(_selectedDay) + 1;

    final isToday = selectedDayIndex == todayWeekday;
    final currentVal = busyList[currentHour];

    IconData statusIcon = Icons.info_outline_rounded;
    Color iconColor = AppColors.charcoal;
    String statusText = isToday ? 'Hiện tại: Trạm bận trung bình' : 'Thông lệ: Trạm bận trung bình';

    final prefix = isToday ? 'Hiện tại: ' : 'Thông lệ: ';
    if (currentVal > 75) {
      statusIcon = Icons.whatshot_rounded;
      iconColor = const Color(0xFFE65100);
      statusText = '${prefix}Giờ cao điểm, thời gian chờ khoảng 15-20 phút';
    } else if (currentVal < 35) {
      statusIcon = Icons.eco_rounded;
      iconColor = const Color(0xFF2E7D32);
      statusText = '${prefix}Trạm đang vắng hơn bình thường';
    }

    final dayLabels = {
      'Thứ 2': 'Thứ 2',
      'Thứ 3': 'Thứ 3',
      'Thứ 4': 'Thứ 4',
      'Thứ 5': 'Thứ 5',
      'Thứ 6': 'Thứ 6',
      'Thứ 7': 'Thứ 7',
      'Chủ nhật': 'Chủ nhật',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.smoke,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thời gian phổ biến',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mức độ sử dụng trạm trung bình theo từng giờ',
                      style: TextStyle(fontSize: 11, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _selectedDay,
                underline: const SizedBox(),
                items: dayLabels.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDay = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                statusIcon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Biểu đồ thời gian phổ biến dạng 24 cột liên tiếp
          Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (hour) {
                    final val = busyList[hour];
                    final isCurrent = isToday && hour == currentHour;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isCurrent)
                              FittedBox(
                                fit: BoxFit.none,
                                child: Text(
                                  '$val%',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              width: double.infinity,
                              height: val * 0.8,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.gray.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Nhãn các mốc giờ chính dưới biểu đồ
              Row(
                children: List.generate(24, (hour) {
                  String label = '';
                  if (hour == 0) {
                    label = '0h';
                  } else if (hour == 6) {
                    label = '6h';
                  } else if (hour == 12) {
                    label = '12h';
                  } else if (hour == 18) {
                    label = '18h';
                  } else if (hour == 23) {
                    label = '23h';
                  }

                  // Hiển thị giờ hiện tại nếu đang xem ngày hôm nay
                  if (isToday && hour == currentHour) {
                    label = '${hour}h';
                  }

                  final isCurrent = isToday && hour == currentHour;

                  return Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : AppColors.gray,
                      ),
                    ),
                  );
                }),
              ),
            ],
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
