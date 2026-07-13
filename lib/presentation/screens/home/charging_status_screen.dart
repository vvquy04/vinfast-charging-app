import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../providers/charging_provider.dart';
import 'charging_receipt_screen.dart';

class ChargingStatusScreen extends StatefulWidget {
  const ChargingStatusScreen({super.key});

  @override
  State<ChargingStatusScreen> createState() => _ChargingStatusScreenState();
}

class _ChargingStatusScreenState extends State<ChargingStatusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChargingProvider>().fetchActiveSession());
  }

  @override
  Widget build(BuildContext context) {
    final chargingProvider = context.watch<ChargingProvider>();
    final session = chargingProvider.activeSession;

    // Nếu không có phiên sạc đang hoạt động và không ở trạng thái loading
    if (session == null && !chargingProvider.isLoading) {
      return const Scaffold(
        body: Center(child: Text('Không có phiên sạc hoạt động!')),
      );
    }

    final stationName = session != null && session['station'] != null
        ? (session['station']['name'] ?? session['station']['stationName'] ?? 'Trạm sạc VinFast').toString()
        : 'Trạm sạc VinFast';
    final connectorType = session != null ? session['connectorType'] as String : 'CCS2';

    // Format thời gian sạc hh:mm:ss
    final duration = Duration(seconds: chargingProvider.chargingElapsedSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    final durationStr = '$hours:$minutes:$seconds';

    return WillPopScope(
      onWillPop: () async => false, // Không cho phép back bằng nút cứng hệ thống
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Bỏ nút back trên appBar
          title: const Text(
            'Đang sạc xe điện',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Station & Connector Header Info
              Text(
                stationName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Cổng sạc: $connectorType',
                style: const TextStyle(fontSize: 13, color: AppColors.gray),
              ),
              const SizedBox(height: 32),

              // 2. Beautiful Battery Charging Animation Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow/Pulse
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.05),
                    ),
                  ),
                  // Progress indicator
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: chargingProvider.simPercent / 100.0,
                      strokeWidth: 12,
                      color: AppColors.success,
                      backgroundColor: AppColors.silver,
                    ),
                  ),
                  // Percent display inside
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 36, color: AppColors.success),
                      Text(
                        '${chargingProvider.simPercent}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const Text(
                        'Dung lượng pin',
                        style: TextStyle(fontSize: 11, color: AppColors.gray),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 3. Stats Row (Time, Energy, Cost)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.access_time_rounded, 'Thời gian', durationStr),
                  _buildStatItem(Icons.bolt_rounded, 'Điện năng', '${chargingProvider.simKwh.toStringAsFixed(2)} kWh'),
                  _buildStatItem(Icons.monetization_on_rounded, 'Tạm tính', '${chargingProvider.simCost.toStringAsFixed(0)}đ'),
                ],
              ),

              const SizedBox(height: 48),

              // 4. Stop Charging Button
              SizedBox(
                width: double.infinity,
                child: chargingProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.black))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          // Lưu các thông số sạc tạm trước khi stop sạc để truyền sang màn hình receipt
                          final kwh = chargingProvider.simKwh;
                          final cost = chargingProvider.simCost;
                          final elapsed = chargingProvider.chargingElapsedSeconds;

                          final success = await chargingProvider.stopCharging();
                          if (success && mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/charging_receipt',
                              arguments: {
                                'stationName': stationName,
                                'connectorType': connectorType,
                                'energyCharged': kwh,
                                'totalCost': cost,
                                'durationSeconds': elapsed,
                              },
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Có lỗi xảy ra khi dừng sạc. Vui lòng thử lại!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'DỪNG SẠC & THANH TOÁN',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.charcoal, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
      ],
    );
  }
}
