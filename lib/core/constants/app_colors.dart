import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية
  static const primary = Color(0xFF6C63FF); // بنفسجي
  static const secondary = Color(0xFF3F51B5); // أزرق غامق
  static const accent = Color(0xFFFF6584); // وردي
  static const background = Color(0xFFF2F2F7); // رمادي فاتح جدا
  static const surface = Colors.white;
  static const error = Color(0xFFE53935);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5EA);

  // تدرجات
  static const List<Color> gradientPrimary = [
    Color(0xFF6C63FF),
    Color(0xFF3F51B5),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFFFF6584),
    Color(0xFFFF4D6D),
  ];

  static const List<Color> gradientTab = [
    Color(0xFFFFFFFF),
    Color(0xFFF0F0F5),
  ];

  static const List<Color> gradientBottomBar = [
    Color(0xFF6C63FF),
    Color(0xFF3F51B5),
  ];
}