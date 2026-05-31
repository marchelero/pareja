import 'package:flutter/material.dart';
import '../../controllers/questions_controller.dart';
import '../../core/models/player.dart';
import 'questions_result_screen.dart';
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
    widget.controller.addListener(_onControllerChange);

    widget.controller.onGameFinished = (Player playerHe, Player playerShe) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionsResultScreen(
            playerHe: playerHe,
            playerShe: playerShe,
          ),
        ),
      );
    };
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
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
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.controller.activateSuddenDeath();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow.shade700,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 10,
                            ),
                            child: const Text('¡EMPEZAR!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
    final c = widget.controller;
    if (c.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final otherPlayer = (c.currentPlayer == c.playerHe) ? c.playerShe : c.playerHe;

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
                          Text('Ronda ${c.currentRound}/${c.maxRounds}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
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
                                label: 'Falló',
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
                                    icon: Icons.star, label: '¡Bien!',
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
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            child: Icon(icon, size: 35),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 3),
              ),
              shadowColor: color.withValues(alpha: 0.5),
            ),
            child: Icon(icon, size: 60, color: iconColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
      ],
    );
  }
}
