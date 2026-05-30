import 'package:flutter/material.dart';
import 'score_board.dart';

class GameWinnerDialog extends StatelessWidget {
  final String winnerName;
  final Color winnerColor;
  final String heName;
  final String sheName;
  final int scoreHe;
  final int scoreShe;
  final int pointsToWin;
  final VoidCallback onVolverAlMenu;

  const GameWinnerDialog({
    super.key,
    required this.winnerName,
    required this.winnerColor,
    required this.heName,
    required this.sheName,
    required this.scoreHe,
    required this.scoreShe,
    required this.pointsToWin,
    required this.onVolverAlMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [winnerColor.withValues(alpha: 0.4), Colors.transparent],
            radius: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 120, color: Colors.amber),
            const SizedBox(height: 30),
            const Text(
              '¡TENEMOS GANADOR!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              winnerName.toUpperCase(),
              style: TextStyle(
                color: winnerColor,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: winnerColor, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ha llegado a $pointsToWin puntos.',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
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
                  const Text('MARCADOR FINAL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 15),
                  ScoreBoard(
                    player1Name: heName,
                    player2Name: sheName,
                    player1Score: scoreHe,
                    player2Score: scoreShe,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: onVolverAlMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: winnerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('VOLVER AL MENÚ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
