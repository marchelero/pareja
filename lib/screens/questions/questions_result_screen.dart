import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/player.dart';
import '../../services/audio_service.dart';
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

class _QuestionsResultScreenState extends State<QuestionsResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AudioService>().playGameOver());
  }

  @override
  Widget build(BuildContext context) {
    Player winner;
    bool isTie = widget.playerHe.score == widget.playerShe.score;

    if (widget.playerHe.score > widget.playerShe.score) {
      winner = widget.playerHe;
    } else {
      winner = widget.playerShe;
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isTie ? Colors.orange.shade100 : (winner == widget.playerHe ? Colors.blue.shade100 : Colors.pink.shade100),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              if (!isTie) ...{
                const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                const SizedBox(height: 10),
                Text(
                  '¡VICTORIA!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: winner == widget.playerHe ? Colors.blue.shade800 : Colors.pink.shade800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  winner.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: winner == widget.playerHe ? Colors.blue : Colors.pink,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                ),
              } else ...{
                const Icon(Icons.handshake, size: 100, color: Colors.orange),
                const SizedBox(height: 10),
                const Text(
                  '¡EMPATE!',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.orange),
                ),
              },
              const SizedBox(height: 40),
              _PlayerStatsCard(player: widget.playerHe, color: Colors.blue, icon: Icons.male),
              const SizedBox(height: 20),
              _PlayerStatsCard(player: widget.playerShe, color: Colors.pink, icon: Icons.female),
              const SizedBox(height: 50),
              _ResultButton(
                text: 'Volver a Jugar',
                color: Colors.green,
                icon: Icons.replay,
                onPressed: () {
                  context.read<AudioService>().playClick();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const QuestionsStartScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
              _ResultButton(
                text: 'Menú Principal',
                color: Colors.blueGrey,
                icon: Icons.menu,
                onPressed: () {
                  context.read<AudioService>().playClick();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const GamesMenuScreen()),
                    (route) => route.isFirst,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  final Player player;
  final Color color;
  final IconData icon;

  const _PlayerStatsCard({required this.player, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 10),
              Text(
                player.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Text(
                '${player.score}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
              ),
              const Text(' pts', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Perfectas', value: player.perfectAnswers, icon: Icons.star, color: Colors.green),
              _StatItem(label: 'Medias', value: player.partialAnswers, icon: Icons.star_half, color: Colors.orange),
              _StatItem(label: 'Falladas', value: player.failedAnswers, icon: Icons.close, color: Colors.red),
            ],
          ),
          // Show sudden death stats if played
          if (player.suddenDeathPoints > 0 || player.suddenDeathCorrect) ...[
            const Divider(height: 30, thickness: 2),
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Muerte Súbita',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (player.suddenDeathCorrect) ...[
                  const Icon(Icons.star, color: Colors.yellow, size: 40),
                  const SizedBox(width: 10),
                  Text(
                    '+${player.suddenDeathPoints} puntos',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ] else ...[
                  const Icon(Icons.sentiment_very_dissatisfied, color: Colors.grey, size: 40),
                  const SizedBox(width: 10),
                  const Text(
                    'Sin puntos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _ResultButton({required this.text, required this.color, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
