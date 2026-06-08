import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

enum GlassCardVariant {
  standard,
  transparent,
  dark,
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurSigma;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final GlassCardVariant variant;
  final List<BoxShadow>? customShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.glassBorderRadius,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.backgroundColor,
    this.blurSigma = AppConstants.glassBlurSigma,
    this.margin,
    this.accentColor,
    this.variant = GlassCardVariant.standard,
    this.customShadows,
  });

  const GlassCard.transparent({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.glassBorderRadius,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.margin,
    this.accentColor,
  }) : backgroundColor = null,
       blurSigma = 0,
       variant = GlassCardVariant.transparent,
       customShadows = null;

  const GlassCard.dark({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.glassBorderRadius,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.margin,
    this.accentColor,
  }) : backgroundColor = Colors.black26,
       blurSigma = AppConstants.glassBlurSigma,
       variant = GlassCardVariant.dark,
       customShadows = null;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = backgroundColor ??
        _defaultBackground();

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: variant == GlassCardVariant.transparent
            ? _buildFlatContainer(effectiveBackground)
            : BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: _buildFlatContainer(effectiveBackground),
              ),
      ),
    );
  }

  Widget _buildFlatContainer(Color bg) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder(0.2),
        ),
        boxShadow: customShadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              if (accentColor != null)
                BoxShadow(
                  color: accentColor!.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
      ),
      child: child,
    );
  }

  Color _defaultBackground() {
    switch (variant) {
      case GlassCardVariant.standard:
        return Colors.white.withValues(alpha: 0.05);
      case GlassCardVariant.transparent:
        return Colors.transparent;
      case GlassCardVariant.dark:
        return Colors.black26;
    }
  }
}
