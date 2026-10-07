import 'package:flutter/material.dart';

/// Central colour palette for the WhereIsIt application.
///
/// This file contains UI colours only. It does not control any application
/// logic, navigation, Firebase behaviour, or data processing.
class AppColors {
  AppColors._();

  // Main dark UI
  static const Color background = Color(0xFF0B1120);
  static const Color card = Color(0xFF172033);
  static const Color cardElevated = Color(0xFF1D2A40);
  static const Color border = Color(0xFF26354D);

  // Blue theme
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color ctaBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color blueSoft = Color(0x1A3B82F6);
  static const Color blueSoftStrong = Color(0x333B82F6);
  static const Color blueBorder = Color(0x663B82F6);

  // Text
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF94A3B8);
  static const Color mutedText = Color(0xFF64748B);

  // Semantic colours — keep their original meanings.
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0x1A22C55E);
  static const Color successSoftStrong = Color(0x3322C55E);
  static const Color successBorder = Color(0x5522C55E);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x1AF59E0B);
  static const Color warningSoftStrong = Color(0x33F59E0B);
  static const Color warningBorder = Color(0x55F59E0B);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0x1AEF4444);
  static const Color errorSoftStrong = Color(0x33EF4444);
  static const Color errorBorder = Color(0x55EF4444);

  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
}
