import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Three-page walkthrough introducing app features.
///
/// Pages: Find Stations → Smart Charging → Community Reviews.
/// Navigation: Skip → [/login-options], Next/Get Started → [/login-options].
class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_PageData> _pages = [
    _PageData(
      icon: Icons.location_on_rounded,
      decorIcon: Icons.map_rounded,
      title: 'Tìm trạm sạc điện\ngần bạn',
      subtitle:
          'Dễ dàng xác định vị trí trạm sạc xung quanh bạn với thông tin khoảng cách và tình trạng thực.',
    ),
    _PageData(
      icon: Icons.bolt_rounded,
      decorIcon: Icons.battery_charging_full_rounded,
      title: 'Trải nghiệm sạc\nthông minh',
      subtitle:
          'Nhận đề xuất cá nhân hóa dựa trên mẫu xe và loại súng sạc ưu tiên của bạn.',
    ),
    _PageData(
      icon: Icons.star_rounded,
      decorIcon: Icons.people_rounded,
      title: 'Đánh giá & chia sẻ\ntừ cộng đồng',
      subtitle:
          'Đọc đánh giá từ những người dùng EV khác và chia sẻ kinh nghiệm sạc của riêng bạn.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login-options');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Page content ──────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _Illustration(page: page),
                        const Spacer(flex: 2),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── Page indicator ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final bool active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.black : AppColors.silver,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSizes.xl),

            // ─── Buttons ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Bỏ qua',
                      style: AppButtonStyle.text,
                      onPressed: _goToLogin,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: AppButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Bắt đầu'
                          : 'Tiếp theo',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

// ─── Illustration widget ──────────────────────────
class _Illustration extends StatelessWidget {
  final _PageData page;
  const _Illustration({required this.page});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              color: AppColors.smoke,
              shape: BoxShape.circle,
            ),
          ),
          // Inner ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.silver.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
          ),
          // Main icon
          Icon(page.icon, size: 72, color: AppColors.black),
          // Decorative floating icon
          Positioned(
            top: 28,
            right: 28,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(page.decorIcon, size: 22, color: AppColors.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────
class _PageData {
  final IconData icon;
  final IconData decorIcon;
  final String title;
  final String subtitle;

  const _PageData({
    required this.icon,
    required this.decorIcon,
    required this.title,
    required this.subtitle,
  });
}
