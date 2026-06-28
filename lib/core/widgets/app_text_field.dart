import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Ô nhập liệu có nhãn, trạng thái lỗi và thiết kế đồng bộ.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
          cursorColor: AppColors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.smoke,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.silver),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.silver),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.black, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
