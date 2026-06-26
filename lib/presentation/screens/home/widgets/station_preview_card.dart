import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/station_detail_model.dart';
import '../../../providers/station_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';

class StationPreviewCard extends StatelessWidget {
  final StationDetailModel detail;

  const StationPreviewCard({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StationProvider>();
    final distanceText = '${provider.getDistanceToUser(detail.latitude, detail.longitude).toStringAsFixed(1)} km';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.address,
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
              GestureDetector(
                onTap: () => provider.clearSelection(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.lightGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Đang sử dụng',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.gray,
              ),
              const SizedBox(width: 4),
              Text(
                distanceText,
                style: const TextStyle(fontSize: 13, color: AppColors.gray),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Chi Tiết',
              onPressed: () {
                Navigator.pushNamed(context, '/station_detail');
              },
            ),
          ),
        ],
      ),
    );
  }
}
