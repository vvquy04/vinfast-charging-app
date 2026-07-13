import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../providers/charging_provider.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
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
    final connectors = args['connectors'] as List<dynamic>?;

    final chargingProvider = context.watch<ChargingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đặt chỗ trước trạm sạc',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Station Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.silver),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
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
                          child: const Icon(Icons.ev_station_rounded, color: Color(0xFF2196F3)),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            stationName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
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

              // 2. Select Connector
              const Text(
                'Chọn loại cổng sạc',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _buildConnectorOption('CCS2', 'Sạc siêu nhanh DC'),
                  const SizedBox(width: AppSizes.md),
                  _buildConnectorOption('AC Type 2', 'Sạc thường AC'),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // 3. Deposit Warning Card (Gold/Alert style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
                        SizedBox(width: AppSizes.xs),
                        Text(
                          'Quy định đặt giữ chỗ trạm sạc',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      '• Lịch đặt giữ chỗ có thời hạn tối đa 15 phút.\n'
                      '• Phí đặt giữ chỗ là 20.000đ (sẽ bị tạm giữ).\n'
                      '• Hoàn lại cọc 100% nếu bạn đến trạm sạc xe đúng giờ (nhận diện qua quét QR tại trụ) hoặc chủ động HỦY đặt chỗ trước khi quá hạn.\n'
                      '• Phạt mất cọc 20.000đ nếu quá hạn 15 phút không đến trạm nhận chỗ.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // 4. Wallet Balance & Checkout details
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
                        const Text('Phí đặt chỗ tạm tính', style: TextStyle(color: AppColors.charcoal)),
                        const Text(
                          '20.000 đ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.silver),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số dư ví điện tử của bạn', style: TextStyle(color: AppColors.charcoal)),
                        Text(
                          '${chargingProvider.balance.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: chargingProvider.balance < 20000 ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // 5. Action Buttons
              if (chargingProvider.balance < 20000) ...[
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
                          'Số dư của bạn không đủ để thực hiện giữ chỗ. Vui lòng nạp ví tối thiểu 20.000đ.',
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
                          text: 'Xác nhận đặt giữ chỗ',
                          onPressed: () async {
                            final success = await chargingProvider.createBooking(
                              stationId,
                              _selectedConnector,
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đặt chỗ trạm sạc thành công! Giữ chỗ trong 15 phút.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(context); // Quay về trang chi tiết trạm sạc
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đặt chỗ thất bại, vui lòng thử lại!'),
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

  Widget _buildConnectorOption(String type, String description) {
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
                  fontSize: 15,
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
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
