import 'package:flutter/material.dart';

/// AgroMoz palette — grounded in Mozambican agriculture:
/// machamba green, cashew-flower orange, laterite soil accents.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1B7A3D); // machamba green
  static const Color primaryDark = Color(0xFF0E5228);
  static const Color secondary = Color(0xFFE8730C); // cashew orange
  static const Color secondaryLight = Color(0xFFFFB067);

  // Neutrals
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF7F9F5);
  static const Color surfaceDark = Color(0xFF161D18);
  static const Color backgroundDark = Color(0xFF0E1410);

  // Semantic
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF1976D2);

  static const Color textPrimary = Color(0xFF1A2B1F);
  static const Color textSecondary = Color(0xFF5C6B60);
}
