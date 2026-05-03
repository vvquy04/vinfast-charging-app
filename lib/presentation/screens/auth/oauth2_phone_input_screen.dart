import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Sign-up step 1 for OAuth2 — Enter phone number.
class OAuth2PhoneInputScreen extends StatefulWidget {
  const OAuth2PhoneInputScreen({super.key});

  @override
  State<OAuth2PhoneInputScreen> createState() => _OAuth2PhoneInputScreenState();
}

class _OAuth2PhoneInputScreenState extends State<OAuth2PhoneInputScreen> {
  final _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _phoneController.text.trim().length >= 9 && _agreedToTerms;

  void _continue(Map<String, dynamic> googleData) async {
    final phone = _phoneController.text.trim();

    if (phone.length < 9) {
      setState(() => _phoneError = 'Vui lòng nhập số điện thoại hợp lệ');
      return;
    }
    if (!_agreedToTerms) return;

    final formattedPhone = '0$phone';
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.sendOtp(formattedPhone);
    if (success && mounted) {
      // Pass both phone and googleData to OTP screen
      Navigator.pushNamed(
        context, 
        '/oauth2/otp', 
        arguments: {
          'phone': formattedPhone,
          'googleData': googleData,
        }
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Gửi mã OTP thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              const Text(
                'Gần xong rồi!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.black, letterSpacing: -0.3),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Để bảo mật tài khoản, vui lòng liên kết số điện thoại của bạn với tài khoản Google này.',
                style: TextStyle(fontSize: 15, color: AppColors.gray, height: 1.5),
              ),
              const SizedBox(height: AppSizes.xxl),
              const Text('Số điện thoại', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
              const SizedBox(height: AppSizes.sm),
              Container(
                height: AppSizes.inputHeight,
                decoration: BoxDecoration(
                  color: AppColors.smoke,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: _phoneError != null ? AppColors.error : AppColors.silver),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇻🇳', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text('+84', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          SizedBox(width: 8),
                          SizedBox(height: 28, child: VerticalDivider(color: AppColors.silver, width: 1)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        decoration: const InputDecoration(
                          hintText: '901 234 567',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.md),
                        ),
                        onChanged: (_) => setState(() => _phoneError = null),
                      ),
                    ),
                  ],
                ),
              ),
              if (_phoneError != null) ...[
                const SizedBox(height: AppSizes.xs),
                Text(_phoneError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ],
              const SizedBox(height: AppSizes.lg),
              GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _agreedToTerms ? AppColors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _agreedToTerms ? AppColors.black : AppColors.silver, width: 1.5),
                      ),
                      child: _agreedToTerms ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white) : null,
                    ),
                    const SizedBox(width: AppSizes.sm + 4),
                    const Expanded(
                      child: Text('Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật.', style: TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Tiếp tục',
                isLoading: isLoading,
                onPressed: _isFormValid && !isLoading ? () => _continue(googleData) : null,
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}
