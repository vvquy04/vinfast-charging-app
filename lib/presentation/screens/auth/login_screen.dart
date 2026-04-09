import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Login screen — Email + Password authentication.
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
  bool _isLoading = false;

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

  void _login() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      return;
    }
    if (phone.length < 9) {
      setState(() => _phoneError = 'Please enter a valid phone number');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password');
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }

    // TODO: Call auth API
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to home on success
        // Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Enter your phone number and password to sign in to your account.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ─── Phone field ────────────────────
              AppTextField(
                label: 'Phone Number',
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

              // ─── Password field ─────────────────
              AppTextField(
                label: 'Password',
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

              // ─── Forgot password ────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to forgot password
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Login button ───────────────────
              AppButton(
                text: 'Sign in',
                isLoading: _isLoading,
                onPressed: _isFormValid ? _login : null,
              ),

              const SizedBox(height: AppSizes.xl),

              // ─── Sign up link ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?  ",
                    style: TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // back to options
                      Navigator.pushNamed(context, '/signup/phone');
                    },
                    child: const Text(
                      'Sign up',
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

// ─── Shared back button ───────────────────────────
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
