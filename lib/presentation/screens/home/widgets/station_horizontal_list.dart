import 'package:flutter/material.dart';
import '../../../../data/models/station_summary_model.dart';
import '../../../../core/constants/app_colors.dart';

class StationHorizontalList extends StatelessWidget {
  final List<StationSummaryModel> stations;
  final Function(StationSummaryModel) onStationTap;
  final String? userConnectorType;
  final String? userVehicleModel;

  const StationHorizontalList({
    super.key,
    required this.stations,
    required this.onStationTap,
    this.userConnectorType,
    this.userVehicleModel,
  });

  bool _isStationCompatible(StationSummaryModel station) {
    if (userConnectorType == null) return true;
    return station.connectorTypes.any(
      (c) => c.type.toLowerCase() == userConnectorType!.toLowerCase(),
    );
  }

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
          final totalPorts = station.connectorTypes.fold<int>(
            0,
            (sum, c) => sum + c.totalPorts,
          );
          final isCompatible = _isStationCompatible(station);
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
                    child: Stack(
                      children: [
                        Positioned.fill(
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
                        if (station.matchScore != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getMatchColor(station.matchScore!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${station.matchScore}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cách ${station.distance.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildStatusDot(station.crowdStatus),
                          ],
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
                        Row(
                          children: [
                            Text(
                              '$totalPorts cổng sạc',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (userConnectorType != null) ...[
                              const SizedBox(width: 6),
                              Icon(
                                isCompatible
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_rounded,
                                size: 14,
                                color: isCompatible
                                    ? const Color(0xFF43A047)
                                    : const Color(0xFFF57C00),
                              ),
                            ],
                          ],
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

  Color _getMatchColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50);
    if (score >= 70) return const Color(0xFFFFB300);
    return const Color(0xFFF44336);
  }

  Widget _buildStatusDot(String? status) {
    Color color = AppColors.gray;
    if (status != null) {
      switch (status) {
        case 'EMPTY':
          color = const Color(0xFF4CAF50); // Xanh lá
          break;
        case 'MODERATE':
          color = const Color(0xFFFFC107); // Vàng
          break;
        case 'BUSY':
        case 'MAINTENANCE':
          color = const Color(0xFFF44336); // Đỏ
          break;
      }
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
