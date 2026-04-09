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
                "Let's you in",
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
                text: 'Continue with Google',
                icon: _socialIcon('G', const Color(0xFFDB4437)),
                onPressed: () {
                  // TODO: Implement Google sign-in
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppSocialButton(
                text: 'Continue with Facebook',
                icon: _socialIcon('f', const Color(0xFF4267B2)),
                onPressed: () {
                  // TODO: Implement Facebook sign-in
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppSocialButton(
                text: 'Continue with Apple',
                icon: const Icon(Icons.apple, size: 24, color: AppColors.black),
                onPressed: () {
                  // TODO: Implement Apple sign-in
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
                      'or',
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
                text: 'Sign in',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Sign Up link ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?  ",
                    style: TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/signup/phone'),
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

  // ─── Illustration ───────────────────────────────
  static Widget _buildIllustration() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: AppColors.smoke,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.electric_car_rounded,
            size: 80,
            color: AppColors.black,
          ),
          Positioned(
            top: 20,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 20,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
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
