import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.smoke,
      appBar: AppBar(
        title: const Text('Lịch sử xem trạm'),
        centerTitle: true,
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.historyList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.historyList.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa xem trạm sạc nào.',
                style: TextStyle(color: AppColors.gray, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.lg),
            itemCount: provider.historyList.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
            itemBuilder: (context, index) {
              final item = provider.historyList[index];
              return Dismissible(
                key: Key(item.historyId.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.white),
                ),
                onDismissed: (direction) async {
                  final success = await provider.deleteHistory(item.historyId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa khỏi lịch sử')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage ?? 'Xóa thất bại'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.silver.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.stationImageUrl != null
                            ? Image.network(
                                item.stationImageUrl!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: AppColors.smoke,
                                child: const Icon(Icons.charging_station_rounded, color: AppColors.lightGray),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.stationName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.stationAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.gray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đã xem: ${item.visitCount} lần',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.lastVisited.day}/${item.lastVisited.month}/${item.lastVisited.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
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
              );
            },
          );
        },
      ),
    );
  }
}
