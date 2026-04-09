import 'package:flutter/material.dart';

/// Palette inspirée du design de référence (fintech / accès résident).
abstract final class AppDesignV2 {
  static const Color primary = Color(0xFF4B39EF);
  static const Color primaryDark = Color(0xFF3629B5);
  static const Color background = Color(0xFFF1F4F8);
  static const Color success = Color(0xFF24D193);
  static const Color textPrimary = Color(0xFF14181B);
  static const Color textSecondary = Color(0xFF57636C);
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF1F4F8);
  static BorderRadius radiusCard = BorderRadius.circular(24);
  static BorderRadius radiusSheet = BorderRadius.vertical(top: Radius.circular(28));
}
