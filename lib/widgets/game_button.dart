import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/haptics_service.dart';

enum GameButtonStyle { primary, secondary, danger }

class GameButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final GameButtonStyle style;
  final double height;
  final double? width;
  final Color? customColor;

  const GameButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.style = GameButtonStyle.primary,
    this.height = 65,
    this.width,
    this.customColor,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
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
    final bool isPrimary = widget.style == GameButtonStyle.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
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
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: _buildDecoration(isPrimary),
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
                              alignment: Alignment(-2.0 + t * 4.0, 0.0),
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
                            Icon(widget.icon, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
    );
  }

  BoxDecoration _buildDecoration(bool isPrimary) {
    switch (widget.style) {
      case GameButtonStyle.primary:
        final Color primaryColor = widget.customColor ?? AppColors.primary;
        final Color gradientColor = widget.customColor?.withValues(alpha: 0.55) ?? AppColors.primaryGradient.withValues(alpha: 0.55);
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.85),
              gradientColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        );
      case GameButtonStyle.secondary:
        return BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        );
      case GameButtonStyle.danger:
        return BoxDecoration(
          color: AppColors.scoreLose.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.scoreLose.withValues(alpha: 0.5),
          ),
        );
    }
  }
}
