import 'package:flutter/material.dart';
import '../../controllers/charades_controller.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_winner_dialog.dart';
import '../../widgets/score_board.dart';
import '../../widgets/neon_background.dart';
import '../../core/theme/app_colors.dart';

class CharadesGameScreen extends StatefulWidget {
  final CharadesController controller;

  const CharadesGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CharadesGameScreen> createState() => _CharadesGameScreenState();
}

class _CharadesGameScreenState extends State<CharadesGameScreen> {
  bool _showingPenance = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);

    widget.controller.onGameWinner = (String winnerName) {
      _showWinnerDialog(winnerName);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.isLoading && widget.controller.currentWord == null) {
        widget.controller.showNewWord();
      }
    });
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
    final c = widget.controller;
    if (c.penanceText != null && !_showingPenance) {
      _showPenanceDialog(c.penanceText!);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    widget.controller.cancelTimer();
    super.dispose();
  }

  void _showPenanceDialog(String penanceText) {
    _showingPenance = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 20),
                  const Text('\u00a1PENITENCIA!',
                    style: TextStyle(color: Colors.redAccent, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 20),
                  Text(penanceText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.controller.clearPenance();
                        _showingPenance = false;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) => _showingPenance = false);
  }

  void _showWinnerDialog(String winnerName) {
    final c = widget.controller;
    final Color winnerColor = c.scoreHe >= c.pointsToWin
        ? AppColors.playerHe
        : AppColors.playerShe;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return GameWinnerDialog(
          winnerName: winnerName,
          winnerColor: winnerColor,
          heName: c.heName,
          sheName: c.sheName,
          scoreHe: c.scoreHe,
          scoreShe: c.scoreShe,
          pointsToWin: c.pointsToWin,
          onVolverAlMenu: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.isLoading) {
      return const Scaffold(
        body: NeonBackground(
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    final Color activeColor = c.isHeTurn
        ? AppColors.playerHe
        : AppColors.playerShe;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NeonBackground(
        showIcons: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(c, activeColor),
              const SizedBox(height: 5),
              _buildTurnIndicator(c, activeColor),
              Expanded(child: _buildBody(c, activeColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CharadesController c, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              ScoreBoard(
                player1Name: c.heName,
                player2Name: c.sheName,
                player1Score: c.scoreHe,
                player2Score: c.scoreShe,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStrikes(c.strikesHe, AppColors.playerHe),
                  const SizedBox(width: 8),
                  _buildStrikes(c.strikesShe, AppColors.playerShe),
                ],
              ),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStrikes(int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count.clamp(0, 10), (_) =>
        Padding(
          padding: const EdgeInsets.only(right: 1),
          child: Icon(Icons.bolt, color: color, size: 14),
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(CharadesController c, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        'TURNO DE ${c.currentPlayerName.toUpperCase()}',
        style: TextStyle(
          color: activeColor,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBody(CharadesController c, Color activeColor) {
    if (c.winner != null) {
      return const SizedBox.shrink();
    }

    if (c.roundDone) {
      return _buildPhase3(c, activeColor);
    }

    if (c.turnReady && c.isPlaying) {
      return _buildPhase2(c, activeColor);
    }

    return _buildPhase1(c, activeColor);
  }

  Widget _buildPhase1(CharadesController c, Color activeColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (c.currentWord != null) ...[
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              c.currentWord!.word.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.2,
                shadows: [Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 3))],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _categoryDisplayName(c.currentWord!.category),
            style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const Spacer(flex: 1),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo el m\u00edmico debe ver la pantalla',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: GameButton(
              text: '\u00a1EMPEZAR!',
              icon: Icons.play_arrow,
              onPressed: () {
                widget.controller.audioService.playClick();
                widget.controller.startTurn();
              },
              style: GameButtonStyle.primary,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  Widget _buildPhase2(CharadesController c, Color activeColor) {
    final double progress = c.timerSeconds > 0
        ? c.timeLeft / c.timerSeconds
        : 0.0;
    final Color timerColor = progress > 0.5
        ? Colors.greenAccent
        : progress > 0.25
            ? Colors.amberAccent
            : Colors.redAccent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 20,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.1),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: timerColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: timerColor.withValues(alpha: 0.4), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${c.timeLeft}',
          style: TextStyle(
            color: timerColor,
            fontSize: 80,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: timerColor.withValues(alpha: 0.3), blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 10),
        const Text('segundos', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: GameButton(
            text: '\u2705 ADIVIN\u00d3',
            icon: Icons.celebration,
            onPressed: () {
              widget.controller.audioService.playLevelUp();
              widget.controller.guessCorrect();
            },
            style: GameButtonStyle.primary,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPhase3(CharadesController c, Color activeColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        if (c.wasGuessed) ...[
          const Icon(Icons.celebration, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 20),
          const Text('\u00a1ADIVINADO!',
            style: TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 15),
          Text(
            '+1 PUNTO para ${c.currentPlayerName}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ] else ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 1.0 + (1.0 - value) * 0.2,
                  child: const Icon(Icons.question_mark, size: 80, color: Colors.redAccent),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('\u00a1SE ACAB\u00d3 EL TIEMPO!',
            style: TextStyle(color: Colors.redAccent, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 15),
          _buildStrikeResult(c),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: GameButton(
            text: 'SIGUIENTE RONDA',
            icon: Icons.skip_next,
            onPressed: () {
              widget.controller.audioService.playClick();
              widget.controller.nextRound();
            },
            style: GameButtonStyle.secondary,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStrikeResult(CharadesController c) {
    final List<String> strikedPlayers = [];
    if (c.strikesHe > 0) strikedPlayers.add('${c.heName}: ${"⚡" * c.strikesHe}');
    if (c.strikesShe > 0) strikedPlayers.add('${c.sheName}: ${"⚡" * c.strikesShe}');

    if (strikedPlayers.isEmpty) {
      return const Text('Nadie recibi\u00f3 strike',
        style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold));
    }

    return Column(
      children: strikedPlayers.map((text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  String _categoryDisplayName(String category) {
    const names = {
      'peliculas': 'Pel\u00edculas',
      'acciones': 'Acciones Cotidianas',
      'animales': 'Animales',
      'comidas': 'Comidas',
      'profesiones': 'Profesiones',
      'celebridades': 'Celebridades',
      'posiciones_sexuales': 'Posiciones Sexuales',
    };
    return names[category] ?? category;
  }
}
