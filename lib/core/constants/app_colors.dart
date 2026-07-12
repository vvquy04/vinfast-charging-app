import 'package:flutter/material.dart';

/// Design system color palette — Minimalist Black / White / Charcoal
class AppColors {
  AppColors._();

  // ─── Colors from Logo ───────────────────────────
  static const Color navy = Color(0xFF0F2E5C);
  static const Color iceBlue = Color(0xFFDDE7F0);
  static const Color offWhite = Color(0xFFF8FAFC);
  // ─── Primary Grayscale (Adapted to logo theme) ──
  static const Color black = Color(0xFF0F2E5C);
  static const Color charcoal = Color(0xFF1E385C);
  static const Color darkGray = Color(0xFF4E6382);
  static const Color gray = Color(0xFF7E92B0);
  static const Color lightGray = Color(0xFFB4C5DE);
  static const Color silver = Color(0xFFDDE7F0);
  static const Color smoke = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Accent (chỉ dùng cho trạng thái) ──────────
  static const Color primary = Color(0xFF0F2E5C);
  static const Color error = Color(0xFFFF3D00);
  static const Color success = Color(0xFF0F2E5C);

  // ─── Disabled ───────────────────────────────────
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledText = Color(0xFF94A3B8);
}
