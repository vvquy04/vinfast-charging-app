import 'package:flutter/material.dart';

/// Design system color palette — Minimalist Black / White / Charcoal
class AppColors {
  AppColors._();

  // ─── Primary Grayscale ──────────────────────────
  static const Color black = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color darkGray = Color(0xFF4A4A4A);
  static const Color gray = Color(0xFF888888);
  static const Color lightGray = Color(0xFFBDBDBD);
  static const Color silver = Color(0xFFE0E0E0);
  static const Color smoke = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Accent (chỉ dùng cho trạng thái) ──────────
  static const Color primary = Color(0xFF00C853); // Bright Green
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  // ─── Disabled ───────────────────────────────────
  static const Color disabled = Color(0xFFD0D0D0);
  static const Color disabledText = Color(0xFF9E9E9E);
}
