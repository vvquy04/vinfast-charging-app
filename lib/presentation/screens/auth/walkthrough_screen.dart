import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Màn hình giới thiệu gồm 3 trang về các tính năng của ứng dụng.
///
/// Các trang: Tìm trạm sạc → Quản lý sạc → Đánh giá từ cộng đồng.
/// Điều hướng: Bỏ qua → [/login-options], Bắt đầu/Tiếp theo → [/login-options].
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
      imagePath: 'assets/images/walkthrough_map.jpg',
      title: 'Tìm trạm sạc điện\ngần bạn',
      subtitle:
          'Dễ dàng xác định vị trí trạm sạc xung quanh bạn với thông tin khoảng cách và tình trạng thực.',
    ),
    _PageData(
      imagePath: 'assets/images/walkthrough_charge.jpg',
      title: 'Lịch sử sạc\ntiện lợi',
      subtitle:
          'Xem lại lịch sử trạm sạc gần đầy với đầy đủ thông tin',
    ),
    _PageData(
      imagePath: 'assets/images/walkthrough_review.jpg',
      title: 'Đánh giá & chia sẻ\ntừ cộng đồng',
      subtitle:
          'Đọc đánh giá từ những người dùng khác và chia sẻ kinh nghiệm sạc của riêng bạn.',
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
            // ─── Nội dung trang ──────────────────────
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

            // ─── Chỉ số trang (Dots) ────────────────────
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

            // ─── Nút điều khiển ──────────────────────────
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

// ─── Widget hình minh họa ──────────────────────────
class _Illustration extends StatelessWidget {
  final _PageData page;
  const _Illustration({required this.page});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Image.asset(
        page.imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─── Lớp dữ liệu trang ───────────────────────────────────
class _PageData {
  final String imagePath;
  final String title;
  final String subtitle;

  const _PageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}
