import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  String? _gender;
  String? _dateOfBirth;
  String? _vehicleModel;
  String? _connectorType;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: profile?.fullName);
    _emailController = TextEditingController(text: profile?.email);
    
    // Đồng bộ và chuyển đổi các giá trị cũ MALE/FEMALE sang Nam/Nữ
    if (profile?.gender == 'MALE') {
      _gender = 'Nam';
    } else if (profile?.gender == 'FEMALE') {
      _gender = 'Nữ';
    } else if (profile?.gender == 'OTHER') {
      _gender = 'Khác';
    } else {
      _gender = profile?.gender;
    }
    
    _dateOfBirth = profile?.dateOfBirth;
    _vehicleModel = profile?.vehicleModel;
    _connectorType = profile?.connectorType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      // Optionally upload immediately or wait for form submit
      // We will upload immediately for better UX
      if (mounted) {
        final provider = context.read<ProfileProvider>();
        final url = await provider.uploadAvatar(_imageFile!);
        if (url != null && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
           );
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage ?? 'Lỗi upload ảnh'), backgroundColor: AppColors.error),
           );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth != null ? DateTime.tryParse(_dateOfBirth!) ?? DateTime.now() : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      if (_nameController.text.isNotEmpty) 'fullName': _nameController.text.trim(),
      if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth,
      if (_vehicleModel != null) 'vehicleModel': _vehicleModel,
      if (_connectorType != null) 'connectorType': _connectorType,
    };

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(data);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          final profile = provider.profile;
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              children: [
                // Avatar Upload
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.smoke,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null),
                        child: _imageFile == null && profile?.avatarUrl == null
                            ? const Icon(Icons.person, size: 50, color: AppColors.gray)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Form Fields
                AppTextField(
                  label: 'Họ và tên',
                  controller: _nameController,
                  hint: 'Nhập họ và tên',
                ),
                const SizedBox(height: AppSizes.md),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Nhập email',
                ),
                const SizedBox(height: AppSizes.md),

                // Gender Dropdown
                const Text(
                  'Giới tính',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                ),
                const SizedBox(height: AppSizes.sm),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.smoke,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.silver)),
                  ),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _gender = newValue),
                  hint: const Text('Chọn giới tính'),
                ),
                const SizedBox(height: AppSizes.md),

                // DOB Picker
                const Text(
                  'Ngày sinh',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                ),
                const SizedBox(height: AppSizes.sm),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.smoke,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.silver),
                    ),
                    child: Text(
                      _dateOfBirth ?? 'YYYY-MM-DD',
                      style: TextStyle(fontSize: 16, color: _dateOfBirth == null ? AppColors.lightGray : AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Divider(color: AppColors.smoke, thickness: 2),
                const SizedBox(height: AppSizes.lg),

                // Vehicle Info
                const Text('Dòng xe VinFast', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                const SizedBox(height: AppSizes.sm),
                DropdownButtonFormField<String>(
                  value: _vehicleModel,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.smoke,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.silver)),
                  ),
                  items: ['VF e34', 'VF 5', 'VF 6', 'VF 7', 'VF 8', 'VF 9', 'VF Wild', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _vehicleModel = newValue),
                  hint: const Text('Chọn dòng xe'),
                ),
                const SizedBox(height: AppSizes.md),

                const Text('Loại cổng sạc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                const SizedBox(height: AppSizes.sm),
                DropdownButtonFormField<String>(
                  value: _connectorType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.smoke,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.silver)),
                  ),
                  items: ['CCS2 (DC)', 'Type 2 (AC)', 'CHAdeMO'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _connectorType = newValue),
                  hint: const Text('Chọn cổng sạc'),
                ),

                const SizedBox(height: AppSizes.xl * 2),
                AppButton(
                  text: 'Lưu thay đổi',
                  isLoading: provider.isLoading,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}
