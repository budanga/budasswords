import "package:flutter/material.dart";
import "../../../core/constants/app_colors.dart";

/// Crisp native vector logo badge for Budasswords (no raster images).
class AppLogoBadge extends StatelessWidget {
  final double size;
  final double? iconSize;
  final BorderRadius? borderRadius;

  const AppLogoBadge({
    super.key,
    this.size = 56,
    this.iconSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final actualIconSize = iconSize ?? (size * 0.52);
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE58B43),
            Color(0xFFC7641B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: actualIconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

