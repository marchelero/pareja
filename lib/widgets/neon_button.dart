import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/haptics_service.dart';

enum NeonButtonVariant { primary, secondary, ghost }

class NeonButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final NeonButtonVariant variant;
  final Color? accentColor;
  final double? glowIntensity;

  const NeonButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.variant = NeonButtonVariant.primary,
    this.accentColor,
    this.glowIntensity,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = widget.variant == NeonButtonVariant.primary;
    final bool isGhost = widget.variant == NeonButtonVariant.ghost;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 1.02),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        HapticsService.light();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: double.infinity,
          height: 65,
          child: isGhost
              ? _buildGhostButton()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: isPrimary
                          ? _buildPrimaryDecoration()
                          : _buildSecondaryDecoration(),
                      child: Material(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            if (isPrimary)
                              AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, _) {
                                  final double t = _shimmerController.value;
                                  return Positioned.fill(
                                    child: FractionallySizedBox(
                                      widthFactor: 2.0,
                                      alignment:
                                          Alignment(-2.0 + t * 4.0, 0.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.18),
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(widget.icon,
                                        color: Colors.white, size: 28),
                                    const SizedBox(width: 12),
                                  ],
                                  Text(
                                    widget.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGhostButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildPrimaryDecoration() {
    final glowColor = widget.accentColor ?? AppColors.primaryNeon;
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryNeon, AppColors.secondaryNeon],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.35),
          blurRadius: 15,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: AppColors.secondaryNeon.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: -2,
        ),
      ],
    );
  }

  BoxDecoration _buildSecondaryDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.15),
        width: 0.5,
      ),
    );
  }
}
