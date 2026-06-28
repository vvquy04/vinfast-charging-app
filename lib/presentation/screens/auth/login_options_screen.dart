import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_social_button.dart';

/// Login options screen — "Let's you in".
///
/// Shows social login buttons (mock), sign-in link, and sign-up link.
class LoginOptionsScreen extends StatelessWidget {
  const LoginOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ─── Illustration ────────────────────
              _buildIllustration(),
              const SizedBox(height: AppSizes.lg),

              // ─── Title ──────────────────────────
              const Text(
                "Đăng nhập",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),

              const Spacer(),

              // ─── Social buttons ─────────────────
              AppSocialButton(
                text: 'Tiếp tục với Google',
                icon: _socialIcon('G', const Color(0xFFDB4437)),
                onPressed: () {
                  // TODO: Implement Google sign-in
                },
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Divider ────────────────────────
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.silver)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: Text(
                      'hoặc',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.silver)),
                ],
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Sign In button ─────────────────
              AppButton(
                text: 'Đăng nhập bằng số điện thoại',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Sign Up link ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Chưa có tài khoản?  ",
                    style: TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/signup/phone'),
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

              const SizedBox(height: AppSizes.md),

              // ─── Guest explore link ──────────────
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text(
                  'Khám phá không cần đăng nhập →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Illustration (Logo App) ────────────────────
  static Widget _buildIllustration() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Image.asset(
        'assets/images/logo.jpg',
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  // ─── Social icon helper ─────────────────────────
  static Widget _socialIcon(String letter, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
