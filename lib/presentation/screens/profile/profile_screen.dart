import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../auth/splash_screen.dart';

/// Màn hình Hồ sơ cá nhân.
/// Hiển thị thông tin user + nút sửa + nút đăng xuất.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Tải profile từ server khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Không thể tải thông tin'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.smoke,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: AppColors.gray)
                            : null,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        user.fullName ?? 'Chưa có tên',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phoneNumber,
                        style: const TextStyle(fontSize: 14, color: AppColors.gray),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Info items
                      _buildInfoItem(Icons.email_outlined, 'Email', user.email ?? 'Chưa cập nhật'),
                      _buildInfoItem(Icons.wc_outlined, 'Giới tính', _formatGender(user.gender)),
                      _buildInfoItem(Icons.cake_outlined, 'Ngày sinh', user.dateOfBirth ?? 'Chưa cập nhật'),
                      _buildInfoItem(Icons.directions_car_outlined, 'Dòng xe', user.vehicleModel ?? 'Chưa cập nhật'),
                      _buildInfoItem(Icons.electrical_services_outlined, 'Cổng sạc', user.connectorType ?? 'Chưa cập nhật'),

                      const SizedBox(height: AppSizes.xl),

                      // Nút đăng xuất
                      AppButton(
                        text: 'Đăng xuất',
                        style: AppButtonStyle.outlined,
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const SplashScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Chưa cập nhật';
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      case 'OTHER':
        return 'Khác';
      default:
        return gender;
    }
  }
}
