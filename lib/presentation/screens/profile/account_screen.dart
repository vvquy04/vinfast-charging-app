import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _showDevelopmentSnackBar(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$featureName" đang được phát triển'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.charcoal),
            onPressed: () => _showDevelopmentSnackBar('Menu mở rộng'),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.profile;
          if (profile == null) {
            return const Center(
              child: Text('Không thể tải thông tin hồ sơ'),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
            children: [
              // ─── THẺ HỒ SƠ NGƯỜI DÙNG ─────────────────
              InkWell(
                onTap: _navigateToProfile,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.smoke,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person_rounded, size: 32, color: AppColors.gray)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Name + Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName ?? 'Người dùng EVC',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.phoneNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.gray,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.lightGray,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: AppColors.smoke, thickness: 1, height: 24),

              // ─── DANH SÁCH CÀI ĐẶT ─────────────────────
              _buildSettingsItem(
                icon: Icons.directions_car_filled_rounded,
                title: 'Phương tiện của tôi',
                onTap: _navigateToProfile,
              ),
              _buildSettingsItem(
                icon: Icons.security_rounded,
                title: 'Bảo mật',
                onTap: () => _showDevelopmentSnackBar('Bảo mật'),
              ),
              _buildSettingsItem(
                icon: Icons.translate_rounded,
                title: 'Ngôn ngữ',
                trailingText: 'Tiếng Việt (VN)',
                onTap: () => _showDevelopmentSnackBar('Ngôn ngữ'),
              ),
              _buildSettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Chế độ tối',
                trailingWidget: Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: _isDarkMode,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _isDarkMode = val);
                      _showDevelopmentSnackBar('Chế độ tối');
                    },
                  ),
                ),
                onTap: () {
                  setState(() => _isDarkMode = !_isDarkMode);
                  _showDevelopmentSnackBar('Chế độ tối');
                },
              ),
              _buildSettingsItem(
                icon: Icons.help_outline_rounded,
                title: 'Trung tâm trợ giúp',
                onTap: () => _showDevelopmentSnackBar('Trung tâm trợ giúp'),
              ),
              _buildSettingsItem(
                icon: Icons.lock_outline_rounded,
                title: 'Chính sách bảo mật',
                onTap: () => _showDevelopmentSnackBar('Chính sách bảo mật'),
              ),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'Về EVCPoint',
                onTap: () => _showDevelopmentSnackBar('Về EVCPoint'),
              ),

              // ─── ĐĂNG XUẤT ────────────────────────────
              _buildSettingsItem(
                icon: Icons.logout_rounded,
                title: 'Đăng xuất',
                textColor: AppColors.error,
                iconColor: AppColors.error,
                showArrow: false,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy', style: TextStyle(color: AppColors.gray)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await context.read<AuthProvider>().logout();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login-options',
                        (route) => false,
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    Color? textColor,
    Color iconColor = AppColors.charcoal,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? AppColors.black,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (trailingWidget != null)
              trailingWidget
            else if (showArrow)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.lightGray,
              ),
          ],
        ),
      ),
    );
  }
}
