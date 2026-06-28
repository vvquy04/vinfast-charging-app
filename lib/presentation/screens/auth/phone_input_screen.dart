import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Sign-up step 1 — Enter phone number.
///
/// Collects phone number with +84 prefix, validates and navigates to OTP.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
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

  void _continue() async {
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
      final otp = authProvider.lastSentOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP (Demo): $otp'),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/signup/otp', arguments: formattedPhone);
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

              // ─── Back button ────────────────────
              _BackButton(onTap: () => Navigator.pop(context)),

              const SizedBox(height: AppSizes.xl),

              // ─── Header ─────────────────────────
              const Text(
                'Xin chào 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Vui lòng nhập số điện thoại. Bạn sẽ nhận được mã OTP ở bước tiếp theo để xác thực.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── Label ──────────────────────────
              const Text(
                'Số điện thoại',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // ─── Phone input ────────────────────
              Container(
                height: AppSizes.inputHeight,
                decoration: BoxDecoration(
                  color: AppColors.smoke,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: _phoneError != null
                        ? AppColors.error
                        : AppColors.silver,
                  ),
                ),
                child: Row(
                  children: [
                    // Country code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇻🇳', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text(
                            '+84',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            height: 28,
                            child: VerticalDivider(
                              color: AppColors.silver,
                              width: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                        cursorColor: AppColors.black,
                        decoration: const InputDecoration(
                          hintText: '901 234 567',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: AppColors.lightGray,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.md,
                          ),
                        ),
                        onChanged: (_) =>
                            setState(() => _phoneError = null),
                      ),
                    ),
                  ],
                ),
              ),

              // Error text
              if (_phoneError != null) ...[
                const SizedBox(height: AppSizes.xs),
                Text(
                  _phoneError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.lg),

              // ─── Terms checkbox ─────────────────
              GestureDetector(
                onTap: () =>
                    setState(() => _agreedToTerms = !_agreedToTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _agreedToTerms
                            ? AppColors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreedToTerms
                              ? AppColors.black
                              : AppColors.silver,
                          width: 1.5,
                        ),
                      ),
                      child: _agreedToTerms
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSizes.sm + 4),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Tôi đồng ý với ',
                              style: TextStyle(color: AppColors.gray),
                            ),
                            TextSpan(
                              text: 'Thỏa thuận sử dụng',
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.black.withOpacity(0.4),
                              ),
                            ),
                            const TextSpan(
                              text: ',\n',
                              style: TextStyle(color: AppColors.gray),
                            ),
                            TextSpan(
                              text: 'Điều khoản',
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.black.withOpacity(0.4),
                              ),
                            ),
                            const TextSpan(
                              text: ', và xác nhận tôi trên 17 tuổi.',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ─── Continue button ────────────────
              AppButton(
                text: 'Tiếp tục',
                isLoading: isLoading,
                onPressed: _isFormValid && !isLoading ? _continue : null,
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.smoke,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.black,
        ),
      ),
    );
  }
}
