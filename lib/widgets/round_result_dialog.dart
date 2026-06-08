import 'package:flutter/material.dart';
import 'game_button.dart';
import 'score_board.dart';

class RoundResultDialog extends StatelessWidget {
  final String loserName;
  final int pointsEarned;
  final bool isGoldenRound;
  final String player1Name;
  final String player2Name;
  final int scoreP1;
  final int scoreP2;
  final VoidCallback onSiguienteRonda;

  const RoundResultDialog({
    super.key,
    required this.loserName,
    required this.pointsEarned,
    required this.isGoldenRound,
    required this.player1Name,
    required this.player2Name,
    required this.scoreP1,
    required this.scoreP2,
    required this.onSiguienteRonda,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              '¡BOOM!',
              style: TextStyle(color: Colors.redAccent, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 5),
            ),
            const SizedBox(height: 20),
            Text(
              '¡$loserName explotó!',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (isGoldenRound) ...[
              const SizedBox(height: 10),
              const Text('¡Ronda Dorada! +2 PUNTOS', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text('MARCADOR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 15),
                  ScoreBoard(
                    player1Name: player1Name,
                    player2Name: player2Name,
                    player1Score: scoreP1,
                    player2Score: scoreP2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: GameButton(
                text: 'SIGUIENTE RONDA',
                icon: Icons.skip_next,
                onPressed: onSiguienteRonda,
                style: GameButtonStyle.primary,
                height: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
