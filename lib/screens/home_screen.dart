import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../core/theme/app_colors.dart';
import 'games_menu_screen.dart';
import 'settings_screen.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/route_transitions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    context.read<SettingsProvider>().load();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final heName = settings.heName;
    final sheName = settings.sheName;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              _AnimatedEntry(
                controller: _entryController,
                intervalStart: 0.0,
                intervalEnd: 0.4,
                child: _buildDivider(),
              ),
              const SizedBox(height: 36),
              _AnimatedEntry(
                controller: _entryController,
                intervalStart: 0.0,
                intervalEnd: 0.4,
                child: _buildTitle(),
              ),
              const SizedBox(height: 36),
              _AnimatedEntry(
                controller: _entryController,
                intervalStart: 0.0,
                intervalEnd: 0.4,
                child: _buildDivider(),
              ),
              const SizedBox(height: 14),
              _AnimatedEntry(
                controller: _entryController,
                intervalStart: 0.2,
                intervalEnd: 0.6,
                child: _buildNameBadge(heName, sheName),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _AnimatedEntry(
                      controller: _entryController,
                      intervalStart: 0.4,
                      intervalEnd: 0.8,
                      child: NeonButton(
                        text: 'JUGAR',
                        icon: Icons.play_arrow_rounded,
                        variant: NeonButtonVariant.primary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            RouteTransitions.fadeSlideUp(
                                const GamesMenuScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AnimatedEntry(
                      controller: _entryController,
                      intervalStart: 0.6,
                      intervalEnd: 1.0,
                      child: NeonButton(
                        text: 'AJUSTES',
                        icon: Icons.settings_rounded,
                        variant: NeonButtonVariant.secondary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            RouteTransitions.slideFromRight(
                                const SettingsScreen()),
                          );
                        },
                      ),
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
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppColors.primaryNeon.withValues(alpha: 0.3 + t * 0.4),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 6 + t * 2,
                height: 6 + t * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryNeon,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryNeon
                          .withValues(alpha: 0.5 + t * 0.5),
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
                gradient: LinearGradient(colors: [
                  AppColors.primaryNeon.withValues(alpha: 0.3 + t * 0.4),
                  Colors.transparent,
                ]),
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
                  Shadow(
                    color: AppColors.primaryNeon
                        .withValues(alpha: 0.6 + g * 0.4),
                    blurRadius: 30 + g * 15,
                  ),
                  Shadow(
                    color: AppColors.secondaryNeon
                        .withValues(alpha: 0.3 + g * 0.2),
                    blurRadius: 15 + g * 8,
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -5),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primaryNeon,
                    AppColors.secondaryNeon,
                    AppColors.primaryNeon,
                  ],
                ).createShader(bounds),
                child: Text(
                  'GAMES',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 28,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryNeon
                            .withValues(alpha: 0.4 + g * 0.2),
                        blurRadius: 15 + g * 10,
                      ),
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

  Widget _buildNameBadge(String heName, String sheName) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final double t = _glowController.value;
        final double scale = 1.0 + 0.15 * (0.5 - (t - 0.5).abs() * 2);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2),
              BoxShadow(
                color: AppColors.primaryNeon
                    .withValues(alpha: 0.04 + t * 0.16),
                blurRadius: 12 + t * 8,
                spreadRadius: 1 + t * 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                heName.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite,
                  color: AppColors.primaryNeon.withValues(alpha: 0.8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                sheName.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double value = CurvedAnimation(
          parent: controller,
          curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
        ).value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}
