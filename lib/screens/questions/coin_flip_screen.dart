import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/roulette_controller.dart';
import '../../controllers/questions_controller.dart';
import '../../data/questions_repository.dart';
import '../../services/audio_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/coin_flip_widget.dart';
import '../../widgets/neon_background.dart';
import '../../core/theme/app_colors.dart';
import '../roulette/roulette_game_screen.dart';
import 'questions_game_screen.dart';

class CoinFlipScreen extends StatefulWidget {
  final int maxRounds;
  final List<String> categories;
  final String heName;
  final String sheName;
  final bool isRoulette;
  final bool isDareMode;

  const CoinFlipScreen({
    super.key,
    required this.maxRounds,
    required this.categories,
    required this.heName,
    required this.sheName,
    this.isRoulette = false,
    this.isDareMode = false,
  });

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleAnimation;
  late AnimationController _pulseController;
  final bool _isHeWinner = Random().nextBool();
  bool _showResult = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _titleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.3, curve: Curves.easeOut)),
    );

    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _showResult = true;
      });
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        if (widget.isRoulette) {
          final audioService = context.read<AudioService>();
          final settingsProvider = context.read<SettingsProvider>();
          final controller = RouletteController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            isDareMode: widget.isDareMode,
            startingPlayerIsHe: _isHeWinner,
          );
          await controller.initGame();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RouletteGameScreen(controller: controller),
            ),
          );
        } else {
          final audioService = context.read<AudioService>();
          final settingsProvider = context.read<SettingsProvider>();
          final controller = QuestionsController(
            repository: QuestionsRepository(),
            audioService: audioService,
            settingsProvider: settingsProvider,
            maxRounds: widget.maxRounds,
            categories: widget.categories,
            startingPlayerIsHe: _isHeWinner,
          );
          await controller.initGame();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionsGameScreen(controller: controller),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              AnimatedBuilder(
                animation: _titleAnimation,
                builder: (context, _) {
                  return Opacity(
                    opacity: _titleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _titleAnimation.value)),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final g = _pulseController.value;
                          return ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppColors.primaryNeon.withValues(alpha: 0.5 + g * 0.5),
                                AppColors.secondaryNeon,
                                AppColors.primaryNeon.withValues(alpha: 0.5 + g * 0.5),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              '¿QUIÉN EMPIEZA?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                                height: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              CoinFlipWidget(
                isHeWinner: _isHeWinner,
                controller: _controller,
                heName: widget.heName,
                sheName: widget.sheName,
              ),
              const SizedBox(height: 50),
              if (_showResult)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    final isHe = _isHeWinner;
                    final Color winnerColor = isHe ? Colors.blueAccent : Colors.pinkAccent;
                    final playerName = isHe
                        ? (widget.heName.isEmpty ? 'ÉL' : widget.heName)
                        : (widget.sheName.isEmpty ? 'ELLA' : widget.sheName);

                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.5 + value * 0.5,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: winnerColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    winnerColor.withValues(alpha: 0.15),
                                    winnerColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: winnerColor.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '¡EMPIEZA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white54,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    playerName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: winnerColor,
                                      letterSpacing: 4,
                                      shadows: [
                                        Shadow(
                                          color: winnerColor.withValues(alpha: 0.6),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Preparando juego...',
                                        style: TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
