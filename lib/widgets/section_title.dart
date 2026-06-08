import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final double fontSize;
  final EdgeInsets padding;

  const SectionTitle({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.fontSize = 14,
    this.padding = const EdgeInsets.only(left: 8, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? AppColors.defaultPlayer2Color, size: 24),
            const SizedBox(width: 10),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
