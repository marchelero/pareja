import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeonBackground extends StatelessWidget {
  final Widget? child;
  final bool showIcons;
  final Color? backgroundColor;

  const NeonBackground({
    super.key,
    this.child,
    this.showIcons = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Animated Gradient Background (Fixed or Dynamic)
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: backgroundColor == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.shade900,
                      Colors.purple.shade900,
                      Colors.black,
                    ],
                  )
                : null,
          ),
        ),

        // 2. Floating Icons (Fire, Kisses, Drinks)
        if (showIcons) const _FloatingIconsBackground(),

        // 3. Child Content
        if (child != null) child!,
      ],
    );
  }
}

class _FloatingIconsBackground extends StatefulWidget {
  const _FloatingIconsBackground();

  @override
  State<_FloatingIconsBackground> createState() => _FloatingIconsBackgroundState();
}

class _FloatingIconsBackgroundState extends State<_FloatingIconsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingIcon> _icons = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Create 15 floating icons
    for (int i = 0; i < 15; i++) {
      _icons.add(_FloatingIcon(
        icon: _getRandomIcon(),
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        speed: _random.nextDouble() * 0.0008 + 0.0004,
        angle: _random.nextDouble() * math.pi * 2,
        size: _random.nextDouble() * 25 + 20,
        opacity: _random.nextDouble() * 0.15 + 0.05,
      ));
    }
  }

  IconData _getRandomIcon() {
    final icons = [Icons.favorite, Icons.whatshot, Icons.local_bar, Icons.star, Icons.auto_awesome];
    return icons[_random.nextInt(icons.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _icons.map((item) {
            // Update position
            item.position = Offset(
              (item.position.dx + math.cos(item.angle) * item.speed) % 1.0,
              (item.position.dy + math.sin(item.angle) * item.speed) % 1.0,
            );

            return Positioned(
              left: item.position.dx * MediaQuery.of(context).size.width,
              top: item.position.dy * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: item.opacity,
                child: Icon(item.icon, size: item.size, color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  Offset position;
  final double speed;
  final double angle;
  final double size;
  final double opacity;

  _FloatingIcon({
    required this.icon,
    required this.position,
    required this.speed,
    required this.angle,
    required this.size,
    required this.opacity,
  });
}
