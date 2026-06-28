import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/station_history_model.dart';
import '../../../providers/history_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'history_detail_bottom_sheet.dart';

class HistoryItemCard extends StatelessWidget {
  final StationHistoryModel item;
  final VoidCallback onDelete;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  Future<void> _launchExternalMap(BuildContext context, String name, String address) async {
    final query = Uri.encodeComponent('$name, $address');
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$query');
    final geoUrl = Uri.parse('geo:0,0?q=$query');

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback trực tiếp
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở ứng dụng bản đồ: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryDetailBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final isFav = provider.isFavorite(item.stationId);
    final hasReviewed = provider.reviewedStationIds.contains(item.stationId);

    return Dismissible(
      key: Key(item.historyId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa lịch sử',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.white),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => _showDetailBottomSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: isFav
                ? Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh trạm sạc
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.stationImageUrl != null
                        ? Image.network(
                            item.stationImageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  const SizedBox(width: 12),

                  // Thông tin trạm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.stationName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.stationAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Nhãn 'Đã bình luận' nếu người dùng đã đánh giá trạm này
                        if (hasReviewed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: Color(0xFF43A047),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đã bình luận',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Nút tích Yêu thích (Ngôi sao)
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFav ? const Color(0xFFFFB800) : AppColors.lightGray,
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => provider.toggleFavorite(item.stationId),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.smoke, height: 1),
              ),

              // Hàng thông tin phụ + Nút chỉ đường nhanh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 14, color: AppColors.gray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Đã xem: ${item.visitCount} lần',
                                style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.gray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Gần nhất: ${item.lastVisited.day.toString().padLeft(2, '0')}/${item.lastVisited.month.toString().padLeft(2, '0')}/${item.lastVisited.year}',
                                style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nút Chỉ đường nhanh
                  ElevatedButton.icon(
                    onPressed: () => _launchExternalMap(context, item.stationName, item.stationAddress),
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text(
                      'Chỉ đường',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.smoke,
      child: const Icon(
        Icons.charging_station_rounded,
        color: AppColors.lightGray,
        size: 28,
      ),
    );
  }
}
