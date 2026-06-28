import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import 'home_map_screen.dart';
import '../profile/account_screen.dart';
import '../history/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeMapScreen(),
          isAuthenticated
              ? const HistoryScreen()
              : _buildLoginRequiredPlaceholder(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Lịch sử xem trạm sạc',
                  description: 'Vui lòng đăng nhập để lưu trữ và theo dõi các trạm sạc xe điện bạn đã quan tâm và tìm kiếm.',
                ),
          isAuthenticated
              ? const AccountScreen()
              : _buildLoginRequiredPlaceholder(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Quản lý tài khoản',
                  description: 'Đăng nhập ngay để xem thông tin cá nhân, cập nhật dòng xe VinFast và tùy chọn cổng sạc của bạn.',
                ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1 && isAuthenticated) {
            context.read<HistoryProvider>().fetchHistory();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.black,
        unselectedItemColor: AppColors.lightGray,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      color: AppColors.smoke,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.smoke,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.charcoal),
              ),
              const SizedBox(height: AppSizes.lg),
              
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Đăng nhập ngay',
                  onPressed: () {
                    Navigator.pushNamed(context, '/login-options');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
