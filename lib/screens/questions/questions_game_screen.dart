import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/questions_controller.dart';
import '../../core/models/player.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';

class QuestionsGameScreen extends StatefulWidget {
  final QuestionsController controller;

  const QuestionsGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<QuestionsGameScreen> createState() => _QuestionsGameScreenState();
}

class _QuestionsGameScreenState extends State<QuestionsGameScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.onGameFinished = (player1, player2) {
      _showResult(player1, player2);
    };
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Se muestra una pregunta para el jugador activo.'),
        GameHelpModal.step('2', 'El jugador responde y su pareja tasa la respuesta del 1 al 5.'),
        GameHelpModal.step('3', 'Si la puntuaci\u00f3n es 4 o 5, el jugador gana puntos. Si es 3 o menos, no suma.'),
        GameHelpModal.bullet('Respuesta bien valorada', 'sumas puntos.', Colors.greenAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien llegue primero a la puntuaci\u00f3n objetivo.', Colors.amberAccent, ''),
      ],
    );
  }

  void _showResult(Player player1, Player player2) {
    final settings = context.read<SettingsProvider>();
    final bool isTie = player1.score == player2.score;
    final Player winner = isTie ? player1 : (player1.score > player2.score ? player1 : player2);
    final Color winnerColor = winner == player1 ? settings.player1Color : settings.player2Color;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Preguntas',
          gameColor: const Color(0xFF2196F3),
          winnerName: winner.name,
          winnerColor: winnerColor,
          player1Name: player1.name,
          player2Name: player2.name,
          player1Icon: settings.player1Icon,
          player2Icon: settings.player2Icon,
          player1Color: settings.player1Color,
          player2Color: settings.player2Color,
          scoreP1: player1.score,
          scoreP2: player2.score,
          isTie: isTie,
          p1StatsSection: _buildStatsSection(player1),
          p2StatsSection: _buildStatsSection(player2),
          onReplay: () => Navigator.pop(context),
          onGameMenu: () => Navigator.pop(context),
          onMainMenu: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  Widget _buildStatsSection(Player player) {
    return Column(
      children: [
        if (player.suddenDeathCorrect)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                const SizedBox(width: 6),
                const Text('Muerte Súbita +7', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(icon: Icons.star, value: player.perfectAnswers, color: Colors.greenAccent),
              _StatChip(icon: Icons.star_half, value: player.partialAnswers, color: Colors.orangeAccent),
              _StatChip(icon: Icons.close, value: player.failedAnswers, color: Colors.redAccent),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.controller.onGameFinished = null;
    super.dispose();
  }

  void _activateSuddenDeath() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.black],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(color: Colors.yellow.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50, height: 5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.1), shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.yellow, size: 80),
                  ),
                  const SizedBox(height: 25),
                  const Text('MUERTE SÚBITA', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 15),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Habrá una sola pregunta para cada uno.\n\nSi responden correctamente, ganarán 7 puntos.\n\n¿Están listos para el desafío final?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: GameButton(
                            text: '¡EMPEZAR!',
                            icon: Icons.play_arrow,
                            onPressed: () {
                              Navigator.pop(context);
                              widget.controller.activateSuddenDeath();
                            },
                            style: GameButtonStyle.primary,
                            height: 60,
                            customColor: Colors.yellow.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        if (c.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final otherPlayer = (c.currentPlayer == c.player1) ? c.player2 : c.player1;

        return Scaffold(
          body: NeonBackground(
            backgroundColor: c.backgroundColor,
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text('Ronda ${c.currentRound}/${c.maxRounds}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              GameHelpModal.helpButton(_showHelpModal),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              const Text('Turno de', style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${c.currentPlayer?.name}'.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  otherPlayer.name.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0,
                                    shadows: [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))]),
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text('PREGUNTA:', style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            c.formatQuestionText(c.currentQuestion?.text ?? ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const Spacer(),
                          if (c.isSuddenDeath)
                            Row(
                              children: [
                                Expanded(
                                  child: _SuddenDeathButton(
                                    icon: Icons.sentiment_very_dissatisfied,
                                    label: 'Fall\u00f3',
                                    color: Colors.black.withValues(alpha: 0.7),
                                    iconColor: Colors.white,
                                    onPressed: () => c.addPoints(0),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _SuddenDeathButton(
                                    icon: Icons.star,
                                    label: '+7 puntos',
                                    color: Colors.yellow.shade700,
                                    iconColor: Colors.amber.shade900,
                                    onPressed: () => c.addPoints(7),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ScoreButton(
                                        icon: Icons.close, label: 'Nada',
                                        color: Colors.redAccent.withValues(alpha: 0.3),
                                        onPressed: () => c.addPoints(0),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _ScoreButton(
                                        icon: Icons.star_half, label: 'Medio',
                                        color: Colors.orangeAccent.withValues(alpha: 0.3),
                                        onPressed: () => c.addPoints(1),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _ScoreButton(
                                        icon: Icons.star, label: '\u00a1Bien!',
                                        color: Colors.greenAccent.withValues(alpha: 0.3),
                                        onPressed: () => c.addPoints(2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: OutlinedButton.icon(
                                    onPressed: _activateSuddenDeath,
                                    icon: const Icon(Icons.flash_on, color: Colors.yellow),
                                    label: const Text('MUERTE SÚBITA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ScoreButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: double.infinity,
          child: GameButton(
            text: label,
            icon: icon,
            onPressed: onPressed,
            style: GameButtonStyle.primary,
            height: 70,
            customColor: color,
          ),
        ),
      ],
    );
  }
}

class _SuddenDeathButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;

  const _SuddenDeathButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: double.infinity,
          child: GameButton(
            text: label,
            icon: icon,
            onPressed: onPressed,
            style: GameButtonStyle.primary,
            height: 100,
            customColor: color,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
