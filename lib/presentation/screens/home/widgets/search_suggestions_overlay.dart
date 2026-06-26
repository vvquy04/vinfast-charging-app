import 'package:flutter/material.dart';
import '../../../../data/models/station_summary_model.dart';
import '../../../../core/constants/app_colors.dart';

class SearchSuggestionsOverlay extends StatelessWidget {
  final String query;
  final List<StationSummaryModel> stations;
  final Function(StationSummaryModel) onStationTap;

  const SearchSuggestionsOverlay({
    super.key,
    required this.query,
    required this.stations,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return const SizedBox.shrink();

    final filtered = stations.where((station) {
      return station.name.toLowerCase().contains(cleanQuery) ||
          station.address.toLowerCase().contains(cleanQuery);
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: filtered.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Không tìm thấy trạm sạc nào',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.smoke),
              itemBuilder: (context, index) {
                final station = filtered[index];
                return ListTile(
                  leading: const Icon(
                    Icons.ev_station_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    station.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${station.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray,
                    ),
                  ),
                  onTap: () => onStationTap(station),
                );
              },
            ),
    );
  }
}
