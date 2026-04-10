import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Sign-up step 3 — Complete profile with password.
///
/// Collects: Full Name, Email, Password, Confirm Password, Gender, Date of Birth.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _selectedGender;
  DateTime? _selectedDate;

  // Errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  static const List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _confirmPasswordController.text == _passwordController.text;

  void _pickGender() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.silver,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Chọn Giới Tính',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                ..._genders.map((g) => ListTile(
                      title: Text(
                        g,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedGender == g
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                      trailing: _selectedGender == g
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.black)
                          : null,
                      onTap: () {
                        setState(() => _selectedGender = g);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _continue() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final nameError = Validators.validateEmpty(name, 'full name');
    if (nameError != null) setState(() => _nameError = nameError);

    final inputEmailError = Validators.validateEmail(email);
    if (inputEmailError != null) setState(() => _emailError = inputEmailError);

    final passError = Validators.validatePassword(password);
    if (passError != null) setState(() => _passwordError = passError);

    final confirmPassError = Validators.validateConfirmPassword(confirm, password);
    if (confirmPassError != null) setState(() => _confirmError = confirmPassError);

    if (_nameError != null || _emailError != null || _passwordError != null || _confirmError != null) {
      return;
    }

    final phone = ModalRoute.of(context)?.settings.arguments as String?;
    if (phone == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy số điện thoại của phiên đăng ký này')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      phoneNumber: phone,
      password: password,
      fullName: name,
      email: email.isNotEmpty ? email : null,
    );

    if (success && mounted) {
      Navigator.pushNamed(context, '/signup/vehicle');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng ký thất bại'),
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
        child: Column(
          children: [
            // ─── Top bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, 0),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),

            // ─── Scrollable content ───────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.lg),

                    // ─── Header ───────────────────
                    const Text(
                      'Hoàn thiện hồ sơ 📋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      "Đừng lo, chỉ có bạn mới thấy được những dữ liệu cá nhân này.",
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.gray,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSizes.xl),

                    // ─── Avatar ───────────────────
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.smoke,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.silver, width: 2),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: AppColors.lightGray,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // TODO: Pick avatar image
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.xl),

                    // ─── Full Name ────────────────
                    AppTextField(
                      label: 'Họ và tên',
                      hint: 'Nhập họ tên của bạn',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ─── Email ────────────────────
                    AppTextField(
                      label: 'Email',
                      hint: 'vidu@gmail.com (tùy chọn)',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _emailError,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ─── Password ─────────────────
                    AppTextField(
                      label: 'Mật khẩu',
                      hint: 'Ít nhất 6 ký tự',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.lightGray,
                          size: 20,
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _passwordError = null),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ─── Confirm Password ─────────
                    AppTextField(
                      label: 'Xác nhận Mật khẩu',
                      hint: 'Nhập lại mật khẩu',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      errorText: _confirmError,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.lightGray,
                          size: 20,
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _confirmError = null),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ─── Gender ───────────────────
                    const Text(
                      'Giới tính',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GestureDetector(
                      onTap: _pickGender,
                      child: Container(
                        height: AppSizes.inputHeight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.smoke,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border:
                              Border.all(color: AppColors.silver),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedGender ?? 'Chọn giới tính',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedGender != null
                                      ? AppColors.black
                                      : AppColors.lightGray,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.lightGray,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ─── Date of Birth ────────────
                    const Text(
                      'Ngày sinh',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: AppSizes.inputHeight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.smoke,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border:
                              Border.all(color: AppColors.silver),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'DD/MM/YYYY',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDate != null
                                      ? AppColors.black
                                      : AppColors.lightGray,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.lightGray,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.xxl),

                    // ─── Continue button ──────────
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
          ],
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
