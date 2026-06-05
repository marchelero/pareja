import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CoinFlipWidget extends StatefulWidget {
  final bool isPlayer1Winner;
  final AnimationController controller;
  final String player1Name;
  final String player2Name;
  final IconData player1Icon;
  final IconData player2Icon;
  final Color player1Color;
  final Color player2Color;

  const CoinFlipWidget({
    super.key,
    required this.isPlayer1Winner,
    required this.controller,
    required this.player1Name,
    required this.player2Name,
    required this.player1Icon,
    required this.player2Icon,
    required this.player1Color,
    required this.player2Color,
  });

  @override
  State<CoinFlipWidget> createState() => _CoinFlipWidgetState();
}

class _CoinFlipWidgetState extends State<CoinFlipWidget> with TickerProviderStateMixin {
  late Animation<double> _spinAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    final double endValue = 7 * 2 * pi + (widget.isPlayer1Winner ? 0 : pi);

    _spinAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: widget.controller, curve: Curves.easeOutCubic),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.85, 1.0, curve: Curves.elasticOut),
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinAnimation, _bounceAnimation, _glowAnimation]),
      builder: (context, child) {
        final angle = _spinAnimation.value;
        final isFront = (angle % (2 * pi)) < pi / 2 || (angle % (2 * pi)) > 3 * pi / 2;
        final bounceOffset = sin(_bounceAnimation.value * pi) * 15;
        final glow = _glowAnimation.value;
        final isP1 = widget.isPlayer1Winner;
        final Color glowColor = isP1 ? widget.player1Color : widget.player2Color;

        return Transform.translate(
          offset: Offset(0, -bounceOffset),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: glow * 0.6),
                  blurRadius: 30 + glow * 20,
                  spreadRadius: 5 + glow * 10,
                ),
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: glow * 0.2),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.003)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFront
                  ? _buildFace(true, glow)
                  : Transform(
                      transform: Matrix4.identity()..setEntry(0, 0, -1.0),
                      alignment: Alignment.center,
                      child: _buildFace(false, glow),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFace(bool isP1, double glow) {
    final Color faceColor = isP1 ? widget.player1Color : widget.player2Color;
    final Color bgColor = isP1 ? const Color(0xFF1A237E) : const Color(0xFF4A0020);
    final IconData icon = isP1 ? widget.player1Icon : widget.player2Icon;
    final String name = isP1 ? widget.player1Name.toUpperCase() : widget.player2Name.toUpperCase();

    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            faceColor.withValues(alpha: 0.3),
            bgColor,
            Colors.black,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: faceColor.withValues(alpha: 0.6 + glow * 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: faceColor.withValues(alpha: 0.3 + glow * 0.3),
            blurRadius: 20 + glow * 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 70,
              color: faceColor.withValues(alpha: 0.7 + glow * 0.3),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: faceColor.withValues(alpha: 0.7 + glow * 0.3),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
