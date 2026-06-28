import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Màn hình đổi mật khẩu (cho người dùng đã đăng nhập).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  void _changePassword() async {
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
    });

    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty) {
      setState(() => _currentError = 'Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _newError = 'Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (newPass != confirm) {
      setState(() => _confirmError = 'Xác nhận mật khẩu không khớp');
      return;
    }
    if (current == newPass) {
      setState(() => _newError = 'Mật khẩu mới phải khác mật khẩu hiện tại');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(current, newPass, confirm);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đổi mật khẩu thất bại'),
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
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.md),

              // ─── Icon header ──────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              const Center(
                child: Text(
                  'Cập nhật mật khẩu mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.sm),

              const Center(
                child: Text(
                  'Nhập mật khẩu hiện tại và mật khẩu mới để thay đổi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── Current password ─────────────────
              AppTextField(
                label: 'Mật khẩu hiện tại',
                hint: '••••••••',
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                errorText: _currentError,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.lightGray, size: 20),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  child: Icon(
                    _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.lightGray, size: 20,
                  ),
                ),
                onChanged: (_) => setState(() => _currentError = null),
              ),

              const SizedBox(height: AppSizes.lg),

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
                text: 'Đổi mật khẩu',
                isLoading: isLoading,
                onPressed: _isFormValid && !isLoading ? _changePassword : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
