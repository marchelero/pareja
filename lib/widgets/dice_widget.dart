import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  final double size;
  final double rotation;

  const DiceWidget({
    super.key,
    required this.value,
    this.size = 80,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value >= 1 && value <= 6;
    final bgColor = isActive ? Colors.white : const Color(0xFF555555);
    final dotColor = isActive ? Colors.black87 : const Color(0xFF333333);

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: _buildDots(isActive ? value : 0, dotColor),
      ),
    );
  }

  Widget _buildDots(int value, Color dotColor) {
    final positions = _dotPositions(value);
    return Stack(
      children: [
        for (final pos in positions)
          Positioned.fill(
            child: Align(
              alignment: Alignment(pos.dx, pos.dy),
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const List<_DotPos> _empty = [];
  static const List<_DotPos> _one = [_DotPos(0, 0)];
  static const List<_DotPos> _two = [_DotPos(-0.5, -0.5), _DotPos(0.5, 0.5)];
  static const List<_DotPos> _three = [
    _DotPos(-0.5, -0.5),
    _DotPos(0, 0),
    _DotPos(0.5, 0.5),
  ];
  static const List<_DotPos> _four = [
    _DotPos(-0.5, -0.5),
    _DotPos(0.5, -0.5),
    _DotPos(-0.5, 0.5),
    _DotPos(0.5, 0.5),
  ];
  static const List<_DotPos> _five = [
    _DotPos(-0.5, -0.5),
    _DotPos(0.5, -0.5),
    _DotPos(0, 0),
    _DotPos(-0.5, 0.5),
    _DotPos(0.5, 0.5),
  ];
  static const List<_DotPos> _six = [
    _DotPos(-0.5, -0.5),
    _DotPos(0.5, -0.5),
    _DotPos(-0.5, 0),
    _DotPos(0.5, 0),
    _DotPos(-0.5, 0.5),
    _DotPos(0.5, 0.5),
  ];

  List<_DotPos> _dotPositions(int value) {
    switch (value) {
      case 0:
        return _empty;
      case 1:
        return _one;
      case 2:
        return _two;
      case 3:
        return _three;
      case 4:
        return _four;
      case 5:
        return _five;
      case 6:
        return _six;
      default:
        return _empty;
    }
  }
}

class _DotPos {
  final double dx;
  final double dy;
  const _DotPos(this.dx, this.dy);
}
