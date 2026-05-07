import 'dart:ui';

/// Central color palette for Budasswords.
/// Dark-first, purple-accented design.
abstract class AppColors {
  // Background layers
  static const bg0 = Color(0xFF0D0D12); // deepest background
  static const bg1 = Color(0xFF13131A); // main surface
  static const bg2 = Color(0xFF1A1A24); // elevated card
  static const bg3 = Color(0xFF222232); // input / hover

  // Brand / accent
  static const accent        = Color(0xFF7C5CFC); // vivid violet
  static const accentSoft    = Color(0xFF9B80FF);
  static const accentDim     = Color(0xFF3D2F8F);
  static const accentGlow    = Color(0x337C5CFC);

  // Semantic
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger  = Color(0xFFFC5C5C);

  // Text
  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF9090B0);
  static const textDisabled  = Color(0xFF505070);

  // Border / divider
  static const border        = Color(0xFF2A2A3E);
  static const borderFocus   = Color(0xFF7C5CFC);
}
