import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Màn hình đặt lại mật khẩu mới (luồng Quên mật khẩu — sau khi verify OTP).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  void _resetPassword() async {
    setState(() {
      _newError = null;
      _confirmError = null;
    });

    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() => _newError = 'Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (newPass != confirm) {
      setState(() => _confirmError = 'Xác nhận mật khẩu không khớp');
      return;
    }

    // Lấy phoneNumber từ route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phoneNumber = args?['phoneNumber'] as String?;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy số điện thoại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(phoneNumber, newPass, confirm);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppColors.primary,
        ),
      );
      // Quay về màn hình đăng nhập
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đặt lại mật khẩu thất bại'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),

              // ─── Back button ──────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              ),

              const SizedBox(height: AppSizes.xl),

              // ─── Title ────────────────────────────
              const Text(
                'Đặt lại mật khẩu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Nhập mật khẩu mới cho tài khoản của bạn.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── New password ─────────────────────
              AppTextField(
                label: 'Mật khẩu mới',
                hint: '••••••••',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                errorText: _newError,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.lightGray, size: 20),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureNew = !_obscureNew),
                  child: Icon(
                    _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.lightGray, size: 20,
                  ),
                ),
                onChanged: (_) => setState(() => _newError = null),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Confirm new password ─────────────
              AppTextField(
                label: 'Xác nhận mật khẩu mới',
                hint: '••••••••',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                errorText: _confirmError,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.lightGray, size: 20),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.lightGray, size: 20,
                  ),
                ),
                onChanged: (_) => setState(() => _confirmError = null),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── Submit button ────────────────────
              AppButton(
                text: 'Xác nhận',
                isLoading: isLoading,
                onPressed: _isFormValid && !isLoading ? _resetPassword : null,
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}
