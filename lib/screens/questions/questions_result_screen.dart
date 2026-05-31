import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/models/player.dart';
import '../../services/audio_service.dart';
import '../../widgets/neon_background.dart';
import '../games_menu_screen.dart';
import 'questions_start_screen.dart';

class QuestionsResultScreen extends StatefulWidget {
  final Player playerHe;
  final Player playerShe;

  const QuestionsResultScreen({
    super.key,
    required this.playerHe,
    required this.playerShe,
  });

  @override
  State<QuestionsResultScreen> createState() => _QuestionsResultScreenState();
}

class _QuestionsResultScreenState extends State<QuestionsResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

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
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTie = widget.playerHe.score == widget.playerShe.score;
    final winner =
        widget.playerHe.score > widget.playerShe.score
            ? widget.playerHe
            : widget.playerShe;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  // --- HEADER ---
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.0,
                    child: _buildHeader(isTie, winner),
                  ),
                  const SizedBox(height: 30),

                  // --- STATS ÉL ---
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.2,
                    child: _PlayerStatsCard(
                      player: widget.playerHe,
                      color: const Color(0xFF4FC3F7),
                      icon: Icons.male,
                      isWinner: !isTie && winner.name == widget.playerHe.name,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- STATS ELLA ---
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.35,
                    child: _PlayerStatsCard(
                      player: widget.playerShe,
                      color: const Color(0xFFF06292),
                      icon: Icons.female,
                      isWinner: !isTie && winner.name == widget.playerShe.name,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- BOTONES ---
                  _AnimatedEntry(
                    controller: _entryController,
                    delay: 0.5,
                    child: Column(
                      children: [
                        _ResultButton(
                          text: 'VOLVER A JUGAR',
                          icon: Icons.replay,
                          gradientColors: const [
                            Color(0xFF2ECC71),
                            Color(0xFF27AE60),
                          ],
                          onPressed: () {
                            context.read<AudioService>().playClick();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuestionsStartScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _ResultButton(
                          text: 'MENÚ PRINCIPAL',
                          icon: Icons.menu,
                          gradientColors: const [
                            Color(0xFF34495E),
                            Color(0xFF2C3E50),
                          ],
                          onPressed: () {
                            context.read<AudioService>().playClick();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GamesMenuScreen(),
                              ),
                              (route) => route.isFirst,
                            );
                          },
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

  Widget _buildHeader(bool isTie, Player winner) {
    return Column(
      children: [
        if (isTie) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB44AFF).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB44AFF).withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.handshake, size: 70, color: Color(0xFFB44AFF)),
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
          const SizedBox(height: 8),
          Text(
            '${widget.playerHe.score} - ${widget.playerShe.score}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, size: 70, color: Color(0xFFFFD700)),
          ),
          const SizedBox(height: 20),
          Text(
            '¡VICTORIA!',
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.name.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: winner.name == widget.playerHe.name
                  ? const Color(0xFF4FC3F7)
                  : const Color(0xFFF06292),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${winner.score} pts',
            style: GoogleFonts.playfairDisplay(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  final Player player;
  final Color color;
  final IconData icon;
  final bool isWinner;

  const _PlayerStatsCard({
    required this.player,
    required this.color,
    required this.icon,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWinner ? color : Colors.white.withValues(alpha: 0.1),
          width: isWinner ? 2.0 : 0.5,
        ),
        boxShadow: [
          if (isWinner)
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // --- HEADER: nombre + score ---
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                player.name,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isWinner ? color : Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${player.score}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isWinner ? color : Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pts',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 8),
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 22),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // --- BARRA DE PROGRESO DEL SCORE ---
          if (player.score > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: player.score / (player.score + 5).clamp(1, 999),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // --- DETALLE DE RESPUESTAS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBadge(
                  label: 'Perfectas',
                  value: player.perfectAnswers,
                  icon: Icons.star,
                  color: const Color(0xFF2ECC71),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _StatBadge(
                  label: 'Medias',
                  value: player.partialAnswers,
                  icon: Icons.star_half,
                  color: const Color(0xFFF39C12),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _StatBadge(
                  label: 'Falladas',
                  value: player.failedAnswers,
                  icon: Icons.close,
                  color: const Color(0xFFE74C3C),
                ),
              ],
            ),
          ),

          // --- MUERTE SÚBITA ---
          if (player.suddenDeathPoints > 0 || player.suddenDeathCorrect) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withValues(alpha: 0.08),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.yellow.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.yellow, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Muerte Súbita',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (player.suddenDeathCorrect)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          '+${player.suddenDeathPoints} pts',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Falló',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onPressed;

  const _ResultButton({
    required this.text,
    required this.icon,
    required this.gradientColors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
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
