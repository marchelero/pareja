import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/atiempo_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptics_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/route_transitions.dart';
import '../games_menu_screen.dart';

class ATiempoGameScreen extends StatefulWidget {
  final ATiempoController controller;

  const ATiempoGameScreen({super.key, required this.controller});

  @override
  State<ATiempoGameScreen> createState() => _ATiempoGameScreenState();
}

class _ATiempoGameScreenState extends State<ATiempoGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _autoAdvanceTimer?.cancel();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    final phase = widget.controller.phase;
    if (phase == ATiempoPhase.turnDone) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        if (widget.controller.p1Time != null && widget.controller.p2Time != null) {
          widget.controller.evaluateComparison();
        } else {
          widget.controller.startNextTurn();
        }
      });
    } else if (phase == ATiempoPhase.bothDone) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        widget.controller.startNextTurn(resetMatch: true);
      });
    } else if (phase == ATiempoPhase.roundOver) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        widget.controller.startNewRound();
      });
    } else if (phase == ATiempoPhase.matchOver) {
      _autoAdvanceTimer?.cancel();
    }
    if (mounted) setState(() {});
  }

  String _formatTime(double time) {
    final seconds = time.toInt();
    final centiseconds = ((time - seconds) * 100).toInt();
    return '${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Cada jugador debe parar el cron\u00f3metro lo m\u00e1s cerca posible del tiempo objetivo.'),
        GameHelpModal.step('2', 'El jugador activo pulsa "PARAR" para detener el tiempo.'),
        GameHelpModal.step('3', 'El que se acerque m\u00e1s al objetivo gana la ronda.'),
        GameHelpModal.bullet('Gana la ronda', 'quien se acerque m\u00e1s al tiempo objetivo.', Colors.greenAccent, 'suma 1 punto'),
        GameHelpModal.bullet('Gana la partida', 'quien gane m\u00e1s rondas.', Colors.amberAccent, 'mejor de 3/5'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: NeonBackground(
        child: SafeArea(
          child: switch (c.phase) {
            ATiempoPhase.matchOver => _buildMatchOver(c),
            _ => _buildGameContent(c),
          },
        ),
      ),
    );
  }

  Widget _buildGameContent(ATiempoController c) {
    return Column(
      children: [
        _buildScoreHeader(c),
        const Spacer(),
        _buildTimerDisplay(c),
        const Spacer(),
        _buildButton(c),
        _buildTurnIndicator(c),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildScoreHeader(ATiempoController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                onPressed: () {
                  HapticsService.light();
                  Navigator.pop(context);
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('RONDA ${c.currentRound}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('${c.p1Rounds} - ${c.p2Rounds}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('rondas', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              GameHelpModal.helpButton(_showHelpModal),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreChip(c.player1Name, c.p1Points, c.player1Color),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              _buildScoreChip(c.player2Name, c.p2Points, c.player2Color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String name, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text('$score', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(ATiempoController c) {
    if (c.phase == ATiempoPhase.bothDone || c.phase == ATiempoPhase.roundOver) {
      return _buildComparisonResult(c);
    }

    final time = switch (c.phase) {
      ATiempoPhase.waitingTurn => '00.00',
      ATiempoPhase.running => _formatTime(c.currentTime),
      ATiempoPhase.turnDone => _formatTime(c.isPlayer1Turn ? (c.p1Time ?? 0) : (c.p2Time ?? 0)),
      _ => '00.00',
    };

    final screenWidth = MediaQuery.of(context).size.width;
    final timerFontSize = ((screenWidth - 80) / 3).clamp(60.0, 120.0);

    return Column(
      key: ValueKey(c.phase),
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) {
            final p = _pulseCtrl.value;
            final isWaiting = c.phase == ATiempoPhase.waitingTurn;
            final goldAlpha = isWaiting ? 0.6 + p * 0.3 : 0.5;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('OBJETIVO', style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: goldAlpha * 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                )),
                const SizedBox(height: 2),
                Text(c.currentTarget.toStringAsFixed(0), style: TextStyle(
                  color: const Color(0xFFFFD700).withValues(alpha: goldAlpha),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  shadows: [
                    Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4 * goldAlpha), blurRadius: 8),
                    Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2 * goldAlpha), blurRadius: 16),
                  ],
                )),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF2020).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF2020).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) {
              final p = _pulseCtrl.value;
              final isWaiting = c.phase == ATiempoPhase.waitingTurn;
              final alpha = isWaiting ? 0.3 + p * 0.15 : 1.0;
              return Text(time, style: TextStyle(
                fontSize: timerFontSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: const Color(0xFFFF2020).withValues(alpha: alpha),
                letterSpacing: 6,
                shadows: [
                  Shadow(color: const Color(0xFFFF2020).withValues(alpha: 0.6 * alpha), blurRadius: 20),
                  Shadow(color: const Color(0xFFFF0000).withValues(alpha: 0.3 * alpha), blurRadius: 40),
                  if (c.phase == ATiempoPhase.turnDone)
                    Shadow(color: const Color(0xFFFF2020).withValues(alpha: 0.8), blurRadius: 60),
                ],
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonResult(ATiempoController c) {
    final p1TimeStr = _formatTime(c.p1Time ?? 0);
    final p2TimeStr = _formatTime(c.p2Time ?? 0);
    final showResult = c.phase == ATiempoPhase.roundOver;
    final target = c.currentTarget;
    final p1Diff = c.p1Time != null ? (c.p1Time! - target).abs() : 999.0;
    final p2Diff = c.p2Time != null ? (c.p2Time! - target).abs() : 999.0;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        final p = _pulseCtrl.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerTimeCard(c.player1Name, c.player1Color, c.player1Icon, p1TimeStr, p1Diff, p1Diff <= p2Diff, p, c, false),
                  const SizedBox(width: 40),
                  _buildPlayerTimeCard(c.player2Name, c.player2Color, c.player2Icon, p2TimeStr, p2Diff, p2Diff <= p1Diff, p, c, false),
                ],
              ),
              if (showResult) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.modeATiempo.withValues(alpha: 0.15 + p * 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.modeATiempo.withValues(alpha: 0.3 + p * 0.3)),
                  ),
                  child: Text('${c.p1Points} - ${c.p2Points}', style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.modeATiempo,
                  )),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerTimeCard(String name, Color color, IconData icon, String time, double diff, bool isWinner, double p, ATiempoController c, bool isRight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (c.phase == ATiempoPhase.roundOver && isWinner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Text('+${c.roundPointsAwarded}', style: TextStyle(
                color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w900,
              )),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isWinner ? 0.2 + p * 0.1 : 0.1),
            border: Border.all(color: color.withValues(alpha: isWinner ? 0.6 + p * 0.3 : 0.3), width: isWinner ? 2 + p * 0.5 : 2),
            boxShadow: isWinner ? [BoxShadow(color: color.withValues(alpha: 0.2 + p * 0.3), blurRadius: 12 + p * 8, spreadRadius: 0)] : null,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(time, style: TextStyle(color: isWinner ? Colors.white : Colors.white.withValues(alpha: 0.6), fontSize: 28, fontWeight: FontWeight.w900)),
        Text('±${diff.toStringAsFixed(2)}', style: TextStyle(color: isWinner ? AppColors.modeATiempo : Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildButton(ATiempoController c) {
    final phase = c.phase;

    if (phase == ATiempoPhase.waitingTurn) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: GameButton(
          text: 'EMPEZAR',
          customColor: AppColors.modeATiempo,
          onPressed: () {
            HapticsService.light();
            c.startTimer();
          },
          style: GameButtonStyle.primary,
        ),
      );
    }

    if (phase == ATiempoPhase.running) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: GameButton(
          text: 'DETENER',
          customColor: Colors.redAccent,
          onPressed: () {
            HapticsService.heavy();
            c.stopTimer();
          },
          style: GameButtonStyle.primary,
        ),
      );
    }

    if (phase == ATiempoPhase.turnDone) {
      return Text('¡LISTO!', style: TextStyle(
        color: AppColors.modeATiempo.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4,
      ));
    }

    return const SizedBox.shrink();
  }

  Widget _buildTurnIndicator(ATiempoController c) {
    if (c.phase != ATiempoPhase.waitingTurn && c.phase != ATiempoPhase.running) {
      return const SizedBox.shrink();
    }

    final playerName = c.isPlayer1Turn ? c.player1Name : c.player2Name;
    final playerColor = c.isPlayer1Turn ? c.player1Color : c.player2Color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text('TURNO DE', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text(playerName.toUpperCase(), style: TextStyle(
            color: playerColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3,
          )),
        ],
      ),
    );
  }

  Widget _buildMatchOver(ATiempoController c) {
    final isP1Winner = c.p1Rounds > c.p2Rounds;
    final winnerName = isP1Winner ? c.player1Name : c.player2Name;
    final winnerColor = isP1Winner ? c.player1Color : c.player2Color;

    return GameResultScreen(
      gameName: 'A TIEMPO',
      gameColor: AppColors.modeATiempo,
      winnerName: winnerName,
      winnerColor: winnerColor,
      player1Name: c.player1Name,
      player2Name: c.player2Name,
      player1Icon: c.player1Icon,
      player2Icon: c.player2Icon,
      player1Color: c.player1Color,
      player2Color: c.player2Color,
      scoreP1: c.p1Rounds,
      scoreP2: c.p2Rounds,
      maxScore: (c.matchRounds ~/ 2) + 1,
      isTie: c.p1Rounds == c.p2Rounds,
      onReplay: () => widget.controller.resetGame(),
      onGameMenu: () => Navigator.pushAndRemoveUntil(
        context, RouteTransitions.slideFromBottom(const GamesMenuScreen()), (route) => false,
      ),
      onMainMenu: () => Navigator.pushAndRemoveUntil(
        context, RouteTransitions.slideFromBottom(const GamesMenuScreen()), (route) => route.isFirst,
      ),
    );
  }
}
