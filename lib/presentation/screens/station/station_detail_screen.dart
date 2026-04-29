import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/history_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = context.read<StationProvider>();
      final detail = stationProvider.selectedStationDetail;
      if (detail != null) {
        context.read<HistoryProvider>().recordVisit(detail.stationId);
      }
    });
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
                  ? Image.network(detail.imageUrl!, fit: BoxFit.cover)
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
                  const SizedBox(height: AppSizes.md),
                  ...detail.connectorTypes.map((connector) {
                    bool available = connector.totalPorts > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.silver),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.smoke,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.electrical_services_rounded, color: AppColors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connector.type,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Công suất: ${connector.powerKw} kW',
                                  style: const TextStyle(fontSize: 13, color: AppColors.gray),
                                )
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: available ? AppColors.primary.withOpacity(0.1) : AppColors.lightGray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${connector.totalPorts} trống',
                              style: TextStyle(
                                  color: available ? AppColors.primary : AppColors.gray,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: AppButton(
            text: 'Đặt lịch sạc điện',
            onPressed: () {
              // TODO: Implement Booking
            },
          ),
        ),
      ),
    );
  }
}
