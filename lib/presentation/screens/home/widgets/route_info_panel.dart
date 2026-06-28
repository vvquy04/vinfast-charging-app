import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RouteInfoPanel extends StatelessWidget {
  final String? routeDistance;
  final String? routeDuration;
  final String? routeDestinationName;
  final VoidCallback onCancel;
  final VoidCallback onStartNavigation;

  const RouteInfoPanel({
    super.key,
    required this.routeDistance,
    required this.routeDuration,
    required this.routeDestinationName,
    required this.onCancel,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Tiêu đề tuyến đường ────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF007AFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đang chỉ đường đến',
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routeDestinationName ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.gray,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Thông tin khoảng cách & thời gian ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Khoảng cách
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            routeDistance ?? '--',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const Text(
                            'Khoảng cách',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.lightGray.withOpacity(0.5),
                ),

                // Thời gian
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            routeDuration ?? '--',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const Text(
                            'Thời gian dự kiến',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Nút thoát chỉ đường (viền outlined)
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray,
                    side: const BorderSide(color: AppColors.lightGray, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nút bắt đầu điều hướng (mở Google/Apple Maps)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStartNavigation,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text(
                    'Bắt đầu đi',
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
}
