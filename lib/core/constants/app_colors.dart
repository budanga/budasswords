import 'dart:ui';

/// Central color palette for Budasswords — The Quiet Archive (Paper Sanctuary).
abstract class AppColors {
  // Background layers
  static const bg0 = Color(0xFFF5F2EB); // Warm oatmeal parchment canvas
  static const bg1 = Color(0xFFFAF8F3); // Light secondary canvas
  static const bg2 = Color(0xFFFFFFFF); // Clean white card surface
  static const bg3 = Color(0xFFEFECE4); // Subtle input / container / hover fill

  // Brand / accent (Warm Terracotta Clay)
  static const accent        = Color(0xFFBA5A3A); // Warm Terracotta
  static const accentSoft    = Color(0xFFD47758); // Soft Terracotta
  static const accentDim     = Color(0xFFF3E5E0); // Light Terracotta tint
  static const accentGlow    = Color(0x22BA5A3A);

  // Semantic
  static const success = Color(0xFF3A604A); // Muted Forest Green
  static const warning = Color(0xFFD97706); // Warm Amber
  static const danger  = Color(0xFFC0392B); // Soft Vermilion

  // Text
  static const textPrimary   = Color(0xFF22201D); // Deep Espresso Charcoal
  static const textSecondary = Color(0xFF767169); // Muted Warm Slate
  static const textDisabled  = Color(0xFFA5A097); // Soft Gray-Stone

  // Border / divider
  static const border        = Color(0xFFDDD9D0); // Fine Sand Rule
  static const borderFocus   = Color(0xFFBA5A3A); // Terracotta Focus
}

