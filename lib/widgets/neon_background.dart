import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ParticleType { circle, heart, star }

class _Particle {
  Offset position;
  double angle;
  double speed;
  double size;
  double opacity;
  Color color;
  ParticleType type;
  double wobblePhase;
  double starOpacity;

  _Particle({
    required this.position,
    required this.angle,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.color,
    required this.type,
    this.wobblePhase = 0,
    this.starOpacity = 0,
  });
}

class NeonBackground extends StatefulWidget {
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
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  late Animation<Alignment> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _gradientAnimation = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Create particles
    final colors = [
      AppColors.primaryNeon,
      AppColors.secondaryNeon,
      AppColors.tertiaryPurple,
    ];

    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        angle: _random.nextDouble() * math.pi * 2,
        speed: _random.nextDouble() * 0.0003 + 0.00015,
        size: _random.nextDouble() * 5 + 3,
        opacity: _random.nextDouble() * 0.09 + 0.03,
        color: colors[_random.nextInt(colors.length)],
        type: ParticleType.values[_random.nextInt(ParticleType.values.length)],
        wobblePhase: _random.nextDouble() * math.pi * 2,
        starOpacity: 0,
      ));
    }
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
          children: [
            // Layer 1: Animated gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                gradient: widget.backgroundColor == null
                    ? LinearGradient(
                        begin: _gradientAnimation.value,
                        end: Alignment(
                          -_gradientAnimation.value.x,
                          -_gradientAnimation.value.y,
                        ),
                        colors: AppColors.backgroundGradient,
                      )
                    : null,
              ),
            ),

            // Layer 2: Particles
            RepaintBoundary(child: _buildParticles()),

            // Layer 3: Child content
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }

  Widget _buildParticles() {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: _particles.map((particle) {
        // Update position
        double dx = particle.position.dx +
            math.cos(particle.angle) * particle.speed;
        double dy = particle.position.dy +
            math.sin(particle.angle) * particle.speed;

        // Wobble for hearts (sine wave trajectory)
        if (particle.type == ParticleType.heart) {
          dy += math.sin(particle.wobblePhase) * 0.001;
          particle.wobblePhase += 0.02;
        }

        // Wrap around
        if (dx < 0) dx = 1.0;
        if (dx > 1.0) dx = 0;
        if (dy < 0) dy = 1.0;
        if (dy > 1.0) dy = 0;

        particle.position = Offset(dx, dy);

        // Twinkle for stars
        double particleOpacity = particle.opacity;
        if (particle.type == ParticleType.star) {
          particleOpacity +=
              math.sin(particle.wobblePhase * 2) * 0.03;
          particleOpacity =
              particleOpacity.clamp(0.02, 0.15).toDouble();
        }

        return Positioned(
          left: particle.position.dx * size.width,
          top: particle.position.dy * size.height,
          child: Opacity(
            opacity: particleOpacity,
            child: _buildParticleWidget(particle),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParticleWidget(_Particle particle) {
    switch (particle.type) {
      case ParticleType.heart:
        return Container(
          width: particle.size * 1.5,
          height: particle.size * 1.5,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
      case ParticleType.star:
        return Transform.rotate(
          angle: particle.wobblePhase,
          child: Container(
            width: particle.size * 1.2,
            height: particle.size * 1.2,
            decoration: BoxDecoration(
              color: particle.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case ParticleType.circle:
        return Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
