import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ScoreBoard extends StatelessWidget {
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final Color player1Color;
  final Color player2Color;

  const ScoreBoard({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    this.player1Color = AppColors.playerHe,
    this.player2Color = AppColors.playerShe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$player1Score',
            style: TextStyle(
              color: player1Color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '-',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 20,
              ),
            ),
          ),
          Text(
            '$player2Score',
            style: TextStyle(
              color: player2Color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
