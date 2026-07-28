import 'package:flutter/material.dart';

/// Design tokens من نظام تصميم MN-DOC (Dark blue #0F2C5C + Tajawal).
class AppColors {
  static const primary = Color(0xFF0F2C5C);
  static const secondary = Color(0xFF1E4DB7);
  static const lightWash = Color(0xFFE8F0FE);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F9FD);
  static const navyDark = Color(0xFF0B1F44);
  static const border = Color(0xFFC8D7F3);

  static const primaryHover = Color(0xFF122F63);
  static const secondaryHover = Color(0xFF1A46A8);
  static const softHover = Color(0xFFDBE8FE);

  static const error = Color(0xFFEA4335);
  static const textPrimary = primary;

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x140F2C5C), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(color: Color(0x400F2C5C), blurRadius: 20, offset: Offset(0, 8)),
  ];
}