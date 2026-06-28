import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/station_detail_model.dart';
import '../../../providers/station_provider.dart';
import '../../../../core/constants/app_colors.dart';

class StationPreviewCard extends StatelessWidget {
  final StationDetailModel detail;
  final VoidCallback? onDirections;
  final String? userConnectorType;
  final String? userVehicleModel;

  const StationPreviewCard({
    super.key,
    required this.detail,
    this.onDirections,
    this.userConnectorType,
    this.userVehicleModel,
  });

  /// Kiểm tra trạm có loại súng sạc tương thích với xe người dùng không
  bool get _isCompatible {
    if (userConnectorType == null) return true;
    final userClean = userConnectorType!.replaceAll(RegExp(r'\s*\([^)]*\)'), '').toLowerCase().trim();
    return detail.connectorTypes.any((c) {
      final stationClean = c.type.replaceAll(RegExp(r'\s*\([^)]*\)'), '').toLowerCase().trim();
      if ((userClean == 'ac' || userClean == 'type2' || userClean == 'type 2') &&
          (stationClean == 'ac' || stationClean == 'type2' || stationClean == 'type 2')) {
        return true;
      }
      return stationClean == userClean;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StationProvider>();
    final distanceKm = provider
        .getDistanceToUser(detail.latitude, detail.longitude)
        .toStringAsFixed(1);

    // Tổng số cổng sạc từ tất cả connector types
    final totalPorts =
        detail.connectorTypes.fold<int>(0, (sum, c) => sum + c.totalPorts);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Row 1: Ảnh + Thông tin ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh trạm sạc
              _buildImage(),
              const SizedBox(width: 12),

              // Thông tin trạm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên trạm
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Địa chỉ
                    Text(
                      detail.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating + Reviews
                    _buildRating(),
                  ],
                ),
              ),

              // Nút đóng
              GestureDetector(
                onTap: () => provider.clearSelection(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.gray,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Row 2: Khoảng cách + Cổng sạc ─────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Khoảng cách
                const Icon(
                  Icons.location_on_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$distanceKm km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),

                const SizedBox(width: 20),

                // Cổng sạc
                const Icon(
                  Icons.ev_station_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalPorts cổng sạc',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),

          // ─── Row 2.5: Nhãn tương thích ──────────────
          if (userConnectorType != null && userVehicleModel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isCompatible
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isCompatible
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFFFB74D),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCompatible
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    size: 16,
                    color: _isCompatible
                        ? const Color(0xFF43A047)
                        : const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isCompatible
                          ? '⚡ Tương thích với $userVehicleModel'
                          : '⚠️ Không tương thích với $userVehicleModel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isCompatible
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ─── Row 3: Hai nút hành động ───────────────
          Row(
            children: [
              // Nút Chi tiết (viền)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/station_detail');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nút Chỉ đường (nền đậm)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text(
                    'Chỉ đường',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Ảnh trạm sạc ──────────────────────────────────
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 90,
        height: 90,
        child: detail.imageUrl != null && detail.imageUrl!.isNotEmpty
            ? Image.network(
                detail.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.smoke,
      child: const Center(
        child: Icon(
          Icons.charging_station_rounded,
          color: AppColors.lightGray,
          size: 36,
        ),
      ),
    );
  }

  // ─── Rating stars ──────────────────────────────────
  Widget _buildRating() {
    return Row(
      children: [
        // Số điểm
        Text(
          detail.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(width: 4),

        // Ngôi sao
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          if (detail.rating >= starValue) {
            icon = Icons.star_rounded;
          } else if (detail.rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_border_rounded;
          }
          return Icon(
            icon,
            size: 16,
            color: const Color(0xFFFFB800),
          );
        }),

        const SizedBox(width: 4),

        // Số reviews
        Text(
          '(${detail.totalReviews})',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }
}
