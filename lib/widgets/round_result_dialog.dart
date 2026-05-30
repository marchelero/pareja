import 'package:flutter/material.dart';
import 'score_board.dart';

class RoundResultDialog extends StatelessWidget {
  final String loserName;
  final int pointsEarned;
  final bool isGoldenRound;
  final String heName;
  final String sheName;
  final int scoreHe;
  final int scoreShe;
  final VoidCallback onSiguienteRonda;

  const RoundResultDialog({
    super.key,
    required this.loserName,
    required this.pointsEarned,
    required this.isGoldenRound,
    required this.heName,
    required this.sheName,
    required this.scoreHe,
    required this.scoreShe,
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
                onPressed: onSiguienteRonda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('SIGUIENTE RONDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
