import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';

class RouteInfoPanel extends StatelessWidget {
  final String? routeDistance;
  final String? routeDuration;
  final String? routeDestinationName;
  final VoidCallback onCancel;

  const RouteInfoPanel({
    super.key,
    required this.routeDistance,
    required this.routeDuration,
    required this.routeDestinationName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(AppSizes.lg),
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
                width: 40,
                height: 40,
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
          const SizedBox(height: 16),

          // ─── Thông tin khoảng cách & thời gian ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 14),

          // ─── Nút thoát chỉ đường ───────────────
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Kết thúc chỉ đường',
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}
