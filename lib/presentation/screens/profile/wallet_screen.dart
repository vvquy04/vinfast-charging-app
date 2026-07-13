import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../providers/charging_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedAmount = 100000;
  final List<int> _presetAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChargingProvider>().fetchWalletBalance());
  }

  @override
  Widget build(BuildContext context) {
    final chargingProvider = context.watch<ChargingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ví điện tử EVCPoint',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek VinFast-style E-Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003087), Color(0xFF0056B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003087).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EVCPoint Wallet',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SỐ DƯ KHẢ DỤNG',
                      style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${chargingProvider.balance.toStringAsFixed(0)} đ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.success, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Ví điện tử Demo hoạt động 24/7',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Select Deposit Amount Label
              const Text(
                'Chọn số tiền cần nạp',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Preset amount selector grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetAmounts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  final amount = _presetAmounts[index];
                  final isSelected = _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.black : AppColors.white,
                        border: Border.all(color: isSelected ? AppColors.black : AppColors.silver, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${amount.toStringAsFixed(0)} đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 3. Action Buttons (Real VNPay & Mock fast deposit)
              SizedBox(
                width: double.infinity,
                child: chargingProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.black))
                    : Column(
                        children: [
                          // Button 1: VNPay Sandbox (Real redirect)
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text: 'Nạp qua cổng VNPay Sandbox',
                              onPressed: () async {
                                final url = await chargingProvider.createVnPayUrl(_selectedAmount);
                                if (url != null) {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    if (mounted) {
                                      _showVerifyPaymentDialog(context);
                                    }
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể mở liên kết thanh toán.'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Button 2: Fast simulated deposit
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.black, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                final success = await chargingProvider.mockDeposit(_selectedAmount);
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Giả lập nạp tiền +${_selectedAmount.toStringAsFixed(0)}đ thành công!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Giả lập nạp tiền thất bại!'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Giả lập nạp tiền nhanh (Không cần thẻ)',
                                style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerifyPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Thanh toán VNPay',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_browser_rounded, size: 48, color: Color(0xFF2196F3)),
              SizedBox(height: 16),
              Text(
                'Vui lòng hoàn thành giao dịch trên trình duyệt vừa mở.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.4),
              ),
              SizedBox(height: 8),
              Text(
                '(Dùng thẻ NCB test: 9704198526191432198, OTP: 123456)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.gray, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<ChargingProvider>().fetchWalletBalance();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Số dư ví điện tử của bạn đã được cập nhật!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Tôi đã hoàn tất thanh toán',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
