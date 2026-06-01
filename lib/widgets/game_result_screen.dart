import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import 'neon_background.dart';
import 'score_board.dart';

class GameResultScreen extends StatefulWidget {
  final String gameName;
  final Color gameColor;
  final String winnerName;
  final Color winnerColor;
  final String heName;
  final String sheName;
  final int scoreHe;
  final int scoreShe;
  final bool isTie;
  final Widget? customStatsSection;
  final VoidCallback onReplay;
  final VoidCallback onGameMenu;
  final VoidCallback onMainMenu;

  const GameResultScreen({
    super.key,
    required this.gameName,
    required this.gameColor,
    required this.winnerName,
    required this.winnerColor,
    required this.heName,
    required this.sheName,
    required this.scoreHe,
    required this.scoreShe,
    this.isTie = false,
    this.customStatsSection,
    required this.onReplay,
    required this.onGameMenu,
    required this.onMainMenu,
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _trophyScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AudioService>().playGameOver(),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _trophyScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.0,
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 30),
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.2,
                    child: _buildScoreboard(),
                  ),
                  if (widget.customStatsSection != null) ...[
                    const SizedBox(height: 20),
                    _AnimatedEntry(
                      controller: _entryController,
                      delay: 0.3,
                      child: widget.customStatsSection!,
                    ),
                  ],
                  const SizedBox(height: 40),
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.5,
                    child: _buildButtons(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pulse = _pulseController;

    if (widget.isTie) {
      return Column(
        children: [
          AnimatedBuilder(
            animation: _trophyScale,
            builder: (context, _) {
              return Transform.scale(
                scale: _trophyScale.value,
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (context, _) {
                    final glow = 0.2 + pulse.value * 0.3;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.gameColor.withValues(alpha: 0.4 + pulse.value * 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gameColor.withValues(alpha: glow),
                            blurRadius: 25 + pulse.value * 15,
                            spreadRadius: 5 + pulse.value * 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.handshake, size: 70, color: Color(0xFFB44AFF)),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '¡EMPATE!',
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFB44AFF),
              letterSpacing: 4,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _trophyScale,
          builder: (context, _) {
            return Transform.scale(
              scale: _trophyScale.value,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, _) {
                  final glow = 0.15 + pulse.value * 0.4;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3 + pulse.value * 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: glow),
                          blurRadius: 30 + pulse.value * 20,
                          spreadRadius: 8 + pulse.value * 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events, size: 80, color: Color(0xFFFFD700)),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFFFFD700),
              Colors.white,
              const Color(0xFFFFD700),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            '¡VICTORIA!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final blur = 12 + pulse.value * 12;
            return Text(
              widget.winnerName.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: widget.winnerColor,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: widget.winnerColor.withValues(alpha: 0.6 + pulse.value * 0.4),
                    blurRadius: blur,
                  ),
                  Shadow(
                    color: widget.winnerColor.withValues(alpha: 0.3),
                    blurRadius: blur * 2,
                  ),
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ScoreBoard(
        player1Name: widget.heName,
        player2Name: widget.sheName,
        player1Score: widget.scoreHe,
        player2Score: widget.scoreShe,
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconButton(
          icon: Icons.replay,
          color: const Color(0xFF2ECC71),
          tooltip: 'Volver a jugar',
          onPressed: () {
            context.read<AudioService>().playClick();
            widget.onReplay();
          },
        ),
        const SizedBox(width: 20),
        _IconButton(
          icon: Icons.menu,
          color: const Color(0xFF3498DB),
          tooltip: 'Menú del juego',
          onPressed: () {
            context.read<AudioService>().playClick();
            widget.onGameMenu();
          },
        ),
        const SizedBox(width: 20),
        _IconButton(
          icon: Icons.home,
          color: const Color(0xFF34495E),
          tooltip: 'Menú principal',
          onPressed: () {
            context.read<AudioService>().playClick();
            widget.onMainMenu();
          },
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double t = ((controller.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
