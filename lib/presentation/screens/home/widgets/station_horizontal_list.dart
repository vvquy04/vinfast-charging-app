import 'package:flutter/material.dart';
import '../../../../data/models/station_summary_model.dart';
import '../../../../core/constants/app_colors.dart';

class StationHorizontalList extends StatelessWidget {
  final List<StationSummaryModel> stations;
  final Function(StationSummaryModel) onStationTap;

  const StationHorizontalList({
    super.key,
    required this.stations,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: stations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final station = stations[index];
          return GestureDetector(
            onTap: () => onStationTap(station),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.smoke,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: station.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              station.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.charging_station_rounded,
                                    color: AppColors.gray,
                                  ),
                            ),
                          )
                        : const Icon(
                            Icons.charging_station_rounded,
                            color: AppColors.gray,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Cách ${station.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cổng sạc sẵn có: ${station.connectorTypes.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
