import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

/// Sign-up step 4 — Add vehicle (optional).
///
/// User can add their VinFast vehicle model and connector type,
/// or skip this step with "Add Later".
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  String? _selectedVehicle;
  String? _selectedConnector;

  static const List<String> _vehicles = [
    'VF e34',
    'VF 3',
    'VF 5',
    'VF 6',
    'VF 7',
    'VF 8',
    'VF 9',
    'VF Wild',
    'VF President',
    'Khác',
  ];

  static const List<String> _connectors = [
    'CCS2 (DC)',
    'Type 2 (AC)',
    'CHAdeMO',
  ];


  void _onVehicleSelected(String vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _selectedConnector = null; // Reset súng sạc để người dùng tùy chọn chọn hoặc không
    });
  }

  void _executeRegistration(Map<String, dynamic> data) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      phoneNumber: data['phoneNumber'],
      password: data['password'],
      fullName: data['fullName'],
      email: data['email'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'],
      avatarUrl: data['avatarUrl'],
      vehicleModel: _selectedVehicle,
      connectorType: _selectedConnector,
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng ký thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _addLater() {
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (data == null) return;
    _executeRegistration(data);
  }

  void _addVehicle() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn mẫu xe'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (data == null) return;
    _executeRegistration(data);
  }

  void _showPicker(
    String title,
    List<String> options,
    String? current,
    ValueChanged<String> onSelect,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: options.map(
                      (opt) => ListTile(
                        title: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: current == opt
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                        trailing: current == opt
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.black,
                              )
                            : null,
                        onTap: () {
                          onSelect(opt);
                          Navigator.pop(context);
                        },
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
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
                'Cá nhân hóa bằng cách thêm xe 🚗',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                "Thông tin xe của bạn được dùng để gợi ý các trạm sạc tương thích.",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 1),

              // ─── Vehicle illustration ───────────
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/walkthrough_charge.jpg',
                    width: 240,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ─── Vehicle Model ──────────────────
              const Text(
                'Mẫu Xe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              _DropdownTile(
                value: _selectedVehicle,
                placeholder: 'Chọn mẫu xe của bạn',
                onTap: () => _showPicker(
                  'Chọn Mẫu Xe',
                  _vehicles,
                  _selectedVehicle,
                  _onVehicleSelected,
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ─── Connector Type ─────────────────
              // Hiển thị dropdown súng sạc như một tùy chọn nâng cao (không bắt buộc) sau khi chọn mẫu xe
              if (_selectedVehicle != null) ...[
                const Text(
                  'Loại Súng Sạc',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                _DropdownTile(
                  value: _selectedConnector,
                  placeholder: 'Chọn loại súng sạc (không bắt buộc)',
                  onTap: () => _showPicker(
                    'Chọn Loại Súng Sạc',
                    _connectors,
                    _selectedConnector,
                    (v) => setState(() => _selectedConnector = v),
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.xl),

              // ─── Buttons ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Thêm Sau',
                      style: AppButtonStyle.outlined,
                      isLoading: isLoading,
                      onPressed: !isLoading ? _addLater : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: AppButton(
                      text: 'Thêm Xe',
                      isLoading: isLoading,
                      onPressed: !isLoading ? _addVehicle : null,
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

// ─── Dropdown tile widget ─────────────────────────
class _DropdownTile extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _DropdownTile({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.smoke,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.silver),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? AppColors.black : AppColors.lightGray,
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
