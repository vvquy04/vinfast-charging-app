import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../providers/charging_provider.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  String _selectedConnector = 'CCS2';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChargingProvider>().fetchWalletBalance());
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final stationId = args['stationId'] as int;
    final stationName = args['stationName'] as String;
    final stationAddress = args['address'] as String;

    final chargingProvider = context.watch<ChargingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thiết lập sạc xe',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.silver),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: Color(0xFF2196F3)),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            stationName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      stationAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Select connector
              const Text(
                'Chọn cổng sạc khả dụng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _buildConnectorOption('CCS2', 'Sạc siêu nhanh DC (150 kW)', 150.0),
                  const SizedBox(width: AppSizes.md),
                  _buildConnectorOption('AC Type 2', 'Sạc thường AC (11 kW)', 11.0),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.smoke,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá điện sạc tiêu chuẩn', style: TextStyle(color: AppColors.charcoal)),
                        const Text(
                          '3.858 đ / kWh',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.silver),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số dư ví điện tử ảo', style: TextStyle(color: AppColors.charcoal)),
                        Text(
                          '${chargingProvider.balance.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: chargingProvider.balance < 50000 ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Action Buttons
              if (chargingProvider.balance < 50000) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Số dư của bạn còn ít hơn 50.000đ. Vui lòng nạp thêm tiền để sạc xe điện.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Nạp ví qua VNPay',
                    onPressed: () {
                      Navigator.pushNamed(context, '/wallet');
                    },
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: chargingProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.black))
                      : AppButton(
                          text: 'Bắt đầu sạc xe',
                          onPressed: () async {
                            final double powerKw = _selectedConnector == 'CCS2' ? 150.0 : 11.0;
                            final success = await chargingProvider.startCharging(
                              stationId,
                              _selectedConnector,
                              powerKw,
                            );
                            if (success && mounted) {
                              Navigator.pushReplacementNamed(context, '/charging_status');
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không thể kích hoạt trụ sạc. Vui lòng thử lại!'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectorOption(String type, String description, double power) {
    final bool isSelected = _selectedConnector == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedConnector = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : AppColors.white,
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.silver,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                type == 'CCS2' ? Icons.flash_on_rounded : Icons.electric_car_rounded,
                color: isSelected ? AppColors.white : AppColors.charcoal,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppColors.silver : AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
