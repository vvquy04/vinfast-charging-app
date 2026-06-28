import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Màn hình đăng nhập bằng số điện thoại và mật khẩu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _phoneController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _login() async {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return;
    }

    final passError = Validators.validatePassword(password);
    if (passError != null) {
      setState(() => _passwordError = passError);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login('0$phone', password);

    if (success && mounted) {
      // Chuyển hướng về trang chủ khi đăng nhập thành công
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted) {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
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

              // ─── Nút quay lại ────────────────────
              _BackButton(onTap: () => Navigator.pop(context)),

              const SizedBox(height: AppSizes.xl),

              // ─── Nhập số điện thoại ────────────────────
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Nhập số điện thoại và mật khẩu để đăng nhập vào tài khoản của bạn.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── Trường số điện thoại ────────────────────
              AppTextField(
                label: 'Số điện thoại',
                hint: '901 234 567',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                errorText: _phoneError,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇻🇳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 4),
                      Text('+84',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black)),
                      SizedBox(width: 8),
                      SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          color: AppColors.silver,
                          width: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() => _phoneError = null),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Trường mật khẩu ─────────────────
              AppTextField(
                label: 'Mật khẩu',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                errorText: _passwordError,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.lightGray,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: _togglePasswordVisibility,
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.lightGray,
                    size: 20,
                  ),
                ),
                onChanged: (_) => setState(() => _passwordError = null),
              ),

              const SizedBox(height: AppSizes.sm),

              // ─── Quên mật khẩu ─────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup/phone', arguments: {'isForgotPassword': true});
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Nút đăng nhập ─────────────────
              AppButton(
                text: 'Đăng nhập',
                isLoading: isLoading,
                onPressed: _isFormValid && !isLoading ? _login : null,
              ),

              const SizedBox(height: AppSizes.xl),

              // ─── Liên kết đăng ký ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Chưa có tài khoản?  ",
                    style: TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, '/signup/phone'),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nút quay lại dùng chung ───────────────────────────
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
