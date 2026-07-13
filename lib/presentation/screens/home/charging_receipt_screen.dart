import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

class ChargingReceiptScreen extends StatelessWidget {
  const ChargingReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final stationName = args['stationName'] as String;
    final connectorType = args['connectorType'] as String;
    final energyCharged = args['energyCharged'] as double;
    final totalCost = args['totalCost'] as double;
    final durationSeconds = args['durationSeconds'] as int;

    // Format thời gian sạc hh:mm:ss
    final duration = Duration(seconds: durationSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    final durationStr = '$hours:$minutes:$seconds';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // 1. Success Icon GFX
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 48),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Thanh toán thành công',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                const Text(
                  'Hóa đơn sạc xe điện của bạn đã được thanh toán',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.gray),
                ),
                const SizedBox(height: AppSizes.xl),

                // 2. Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Trạm sạc', stationName, bold: true),
                      const Divider(height: 24, color: AppColors.silver),
                      _buildReceiptRow('Cổng sạc', connectorType),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Thời lượng sạc', durationStr),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Điện năng tiêu thụ', '${energyCharged.toStringAsFixed(2)} kWh'),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Đơn giá', '3.858đ/kWh'),
                      const Divider(height: 24, color: AppColors.silver),
                      _buildReceiptRow(
                        'Tổng số tiền', 
                        '${totalCost.toStringAsFixed(0)} đ', 
                        bold: true, 
                        color: AppColors.black
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Phương thức', 'Ví điện tử EVCPoint', color: AppColors.success),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Return Home Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'QUAY LẠI TRANG CHỦ',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
