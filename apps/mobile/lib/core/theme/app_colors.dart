import 'package:flutter/material.dart';

/// Grahvani Color Palette
/// Premium Vedic Astrology + AI Spiritual Technology Product
class AppColors {
  // PRIMARY - Burgundy
  static const Color primaryBurgundy = Color(0xFF850E35);
  static const Color primaryBurgundyDark = Color(0xFF650A29);
  static const Color primaryBurgundyDarkest = Color(0xFF42061B);

  // ROSE
  static const Color rose100 = Color(0xFFEE6983);
  static const Color rose200 = Color(0xFFF39AAF);
  static const Color rose300 = Color(0xFFFFC4C4);
  static const Color rose400 = Color(0xFFFFE0E0);

  // LIGHT - Cream backgrounds
  static const Color lightBg = Color(0xFFFCF5EE);
  static const Color lightBgSecondary = Color(0xFFFFF9F5);
  static const Color lightBgRose = Color(0xFFFFF2F3);
  static const Color lightBgWhite = Color(0xFFFFFFFF);

  // DARK MODE
  static const Color darkBg = Color(0xFF18070E);
  static const Color darkBgPrimary = Color(0xFF250914);
  static const Color darkBgSecondary = Color(0xFF350B1B);
  static const Color darkBgElevated = Color(0xFF421126);
  static const Color darkBgAccent = Color(0xFF52152D);
  static const Color darkBgStrong = Color(0xFF631C37);

  // GOLD - Vedic/Premium/Spiritual
  static const Color gold = Color(0xFFD6A85F);
  static const Color goldLight = Color(0xFFE7C27A);
  static const Color goldLighter = Color(0xFFF1D9A6);
  static const Color goldLightest = Color(0xFFF5E7C5);
  static const Color goldDark = Color(0xFFA87532);

  // AI COLORS
  static const Color aiPrimary = Color(0xFFA94D76);
  static const Color aiSecondary = Color(0xFF8B5BA8);
  static const Color aiTertiary = Color(0xFFC7A1D5);

  // TEXT COLORS - Light Mode
  static const Color textPrimaryLight = Color(0xFF3A1722);
  static const Color textSecondaryLight = Color(0xFF704653);
  static const Color textMutedLight = Color(0xFF9B7B84);

  // TEXT COLORS - Dark Mode
  static const Color textPrimaryDark = Color(0xFFFCF5EE);
  static const Color textSecondaryDark = Color(0xFFE4B9C2);
  static const Color textMutedDark = Color(0xFFB98A98);

  // SEMANTIC COLORS
  static const Color success = Color(0xFF3D8B5A);
  static const Color warning = Color(0xFFC8892F);
  static const Color error = Color(0xFFC43D50);
  static const Color info = Color(0xFF5A7FA8);

  // GRADIENTS
  static const List<Color> gradientPrimary = [primaryBurgundy, rose100];
  static const List<Color> gradientDeepBurgundy = [primaryBurgundyDarkest, primaryBurgundy];
  static const List<Color> gradientRose = [rose100, rose300];
  static const List<Color> gradientAI = [aiPrimary, aiSecondary];
  static const List<Color> gradientGold = [goldDark, goldLight];
  static const List<Color> gradientDarkPremium = [darkBg, darkBgSecondary, darkBgStrong];
}
