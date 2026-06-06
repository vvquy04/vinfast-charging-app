import 'package:flutter/material.dart';

/// Design system color palette — Minimalist Black / White / Charcoal
class AppColors {
  AppColors._();

  // ─── Colors from Logo ───────────────────────────
  static const Color navy = Color(0xFF0F2E5C); // Xanh Navy đậm từ logo
  static const Color iceBlue = Color(0xFFDDE7F0); // Xanh đá nhạt từ logo
  static const Color offWhite = Color(0xFFF8FAFC); // Nền off-white từ logo

  // ─── Primary Grayscale (Adapted to logo theme) ──
  static const Color black = Color(0xFF0F2E5C); // Dùng Navy thay đen để sang trọng hơn
  static const Color charcoal = Color(0xFF1E385C); // Navy trầm
  static const Color darkGray = Color(0xFF4E6382); // Navy xám đậm
  static const Color gray = Color(0xFF7E92B0); // Navy xám trung bình
  static const Color lightGray = Color(0xFFB4C5DE); // Navy xám nhạt
  static const Color silver = Color(0xFFDDE7F0); // Trùng màu xanh đá
  static const Color smoke = Color(0xFFF8FAFC); // Trùng màu off-white nền sáng
  static const Color white = Color(0xFFFFFFFF);

  // ─── Accent (chỉ dùng cho trạng thái) ──────────
  static const Color primary = Color(0xFF0F2E5C); // Màu xanh Navy chủ đạo từ logo
  static const Color error = Color(0xFFFF3D00); // Đỏ cam biểu diễn trạm bận
  static const Color success = Color(0xFF0F2E5C); // Xanh Navy biểu diễn trạm rảnh

  // ─── Disabled ───────────────────────────────────
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledText = Color(0xFF94A3B8);
}
