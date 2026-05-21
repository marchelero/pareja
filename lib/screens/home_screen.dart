import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/storage/local_storage.dart';
import 'games_menu_screen.dart';
import 'settings_screen.dart';
import '../widgets/neon_background.dart';

const Color _c1 = Color(0xFFFF8A65);
const Color _c2 = Color(0xFFFFAB40);
const Color _c3 = Color(0xFFFF6E40);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _loadNames();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    if (he.isNotEmpty && she.isNotEmpty) {
      setState(() {
        _heName = he;
        _sheName = she;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              _buildDivider(),

              const SizedBox(height: 36),

              _buildTitle(),

              const SizedBox(height: 36),

              _buildDivider(),

              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  final double t = _glowController.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: _c3.withOpacity(0.04 + t * 0.16),
                          blurRadius: 12 + t * 8,
                          spreadRadius: 1 + t * 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _heName.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, color: _c3.withOpacity(0.8), size: 16),
                        const SizedBox(width: 12),
                        Text(
                          _sheName.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        return _GlassButton(
                          text: 'JUGAR',
                          icon: Icons.play_arrow_rounded,
                          isPrimary: true,
                          glowValue: _glowController.value,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GamesMenuScreen()),
                            ).then((_) => _loadNames());
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _GlassButton(
                      text: 'AJUSTES',
                      icon: Icons.settings_rounded,
                      isPrimary: false,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        ).then((_) => _loadNames());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final double t = _glowController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _c2.withOpacity(0.3 + t * 0.4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 6 + t * 2,
                height: 6 + t * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _c1,
                  boxShadow: [
                    BoxShadow(
                      color: _c2.withOpacity(0.5 + t * 0.5),
                      blurRadius: 8 + t * 8,
                      spreadRadius: 2 + t * 4,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 120,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _c2.withOpacity(0.3 + t * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final double g = _glowController.value;
        return Column(
          children: [
            Text(
              'Date',
              style: GoogleFonts.dancingScript(
                fontSize: 86,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
                shadows: [
                  Shadow(color: _c1.withOpacity(0.6 + g * 0.4), blurRadius: 30 + g * 15),
                  Shadow(color: _c2.withOpacity(0.3 + g * 0.2), blurRadius: 15 + g * 8),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -5),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_c3, _c2, _c1, _c2, _c3],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ).createShader(bounds),
                child: Text(
                  'GAMES',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 28,
                    shadows: [
                      Shadow(color: _c3.withOpacity(0.4 + g * 0.2), blurRadius: 15 + g * 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double glowValue;

  const _GlassButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
    this.glowValue = 0.0,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

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
    final double g = widget.glowValue;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isPrimary
                ? [
                    const Color(0xFFFF416C).withOpacity(0.75 + g * 0.1),
                    const Color(0xFFFF4B2B).withOpacity(0.45 + g * 0.1),
                  ]
                : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isPrimary
                ? const Color(0xFFFF416C).withOpacity(0.4 + g * 0.4)
                : Colors.white.withOpacity(0.2),
              width: widget.isPrimary ? 1.5 + g * 1.0 : 1.0,
            ),
            boxShadow: widget.isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF416C).withOpacity(0.25 + g * 0.25),
                    blurRadius: 12 + g * 12,
                    spreadRadius: 1 + g * 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF4B2B).withOpacity(0.15 + g * 0.15),
                    blurRadius: 20 + g * 10,
                    spreadRadius: -2,
                  ),
                ]
              : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              child: Stack(
                children: [
                  // Shimmer overlay
                  if (widget.isPrimary)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
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
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // Button Content
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
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
    );
  }
}
