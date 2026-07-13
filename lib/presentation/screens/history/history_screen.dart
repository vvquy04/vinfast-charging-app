import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/charging_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'widgets/history_item_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchHistory();
      context.read<ChargingProvider>().fetchChargingHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.smoke,
        appBar: AppBar(
          title: const Text(
            'Nhật ký hoạt động',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Trạm đã xem'),
              Tab(text: 'Lịch sử sạc'),
            ],
            labelColor: AppColors.black,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.black,
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        body: TabBarView(
          children: [
            // ─── TAB 1: TRẠM ĐÃ XEM ─────────────────────────────
            _buildViewedHistoryTab(),

            // ─── TAB 2: LỊCH SỬ SẠC XE ───────────────────────────
            _buildChargingHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewedHistoryTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.historyList.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (provider.historyList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history_rounded,
            title: 'Bạn chưa xem trạm sạc nào',
            description: 'Lịch sử các trạm đã xem sẽ xuất hiện tại đây.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: provider.historyList.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final item = provider.historyList[index];
            return HistoryItemCard(
              item: item,
              onDelete: () async {
                final success = await provider.deleteHistory(item.historyId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa khỏi lịch sử'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChargingHistoryTab() {
    return Consumer<ChargingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.chargingHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (provider.chargingHistory.isEmpty) {
          return _buildEmptyState(
            icon: Icons.bolt_rounded,
            title: 'Chưa có lịch sử sạc xe',
            description: 'Thông tin chi tiết các lần sạc và hóa đơn sẽ lưu giữ tại đây.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: provider.chargingHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, index) {
            final session = provider.chargingHistory[index];
            final stationName = session['station'] != null ? session['station']['stationName'] as String : 'Trạm sạc';
            final totalCost = (session['totalCost'] ?? 0.0) as double;
            final energy = (session['energyCharged'] ?? 0.0) as double;
            final power = (session['powerKw'] ?? 0.0) as double;
            final startTimeStr = session['startTime'] as String;
            final date = DateTime.parse(startTimeStr);
            final dateFormatted = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

            return Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.silver),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateFormatted • Cổng DC $power kW',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Đã sạc: ${energy.toStringAsFixed(2)} kWh',
                          style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    '${totalCost.toStringAsFixed(0)} đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.lightGray),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppColors.gray, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
