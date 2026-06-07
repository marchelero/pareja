import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/duel_controller.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import 'duel_start_screen.dart';
import '../games_menu_screen.dart';

class DuelGameScreen extends StatefulWidget {
  final DuelController controller;

  const DuelGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);

    widget.controller.onGameFinished = ({required String winnerName, required String loserName}) {
      _showResultScreen(winnerName, loserName);
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

  void _showResultScreen(String winnerName, String loserName) {
    final c = widget.controller;
    final bool isHe = winnerName == c.player1Name;
    final Color winnerColor = isHe ? c.player1Color : c.player2Color;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Duelo Nocturno',
          gameColor: AppColors.modeMostLikely,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.player1Name,
          player2Name: c.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: c.player1Score,
          scoreP2: c.player2Score,
          maxScore: c.maxRoundsValue,
          isTie: winnerName == 'EMPATE',
          onReplay: () {
            final newController = DuelController(
              audioService: audioService,
              settingsProvider: settingsProvider,
              maxRounds: c.maxRoundsValue,
            );
            newController.initGame().then((_) {
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DuelGameScreen(controller: newController),
                ),
              );
            });
          },
          onGameMenu: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DuelStartScreen()),
            );
          },
          onMainMenu: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const GamesMenuScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Sale una frase: "\u00bfQui\u00e9n es m\u00e1s probable que...".'),
        GameHelpModal.step('2', 'Discutan y elijan qui\u00e9n se lleva la frase (t\u00fa o \u00e9l/ella).'),
        GameHelpModal.bullet('Pierdes', 'si tu pareja no coincide contigo.', Colors.redAccent, ''),
        GameHelpModal.bullet('Ganas', 'si tu pareja coincide contigo.', Colors.greenAccent, ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(c),
              const SizedBox(height: 10),
              _buildProgress(c),
              const Spacer(),
              _buildTaskCard(c),
              const Spacer(),
              _buildActionButtons(c),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DuelController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              _buildScoreChip(c.player1Name, c.player1Score, c.player1Color),
              const SizedBox(width: 8),
              const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(width: 8),
              _buildScoreChip(c.player2Name, c.player2Score, c.player2Color),
            ],
          ),
          GameHelpModal.helpButton(_showHelpModal),
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
          Text(
            name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(DuelController c) {
    final progress = c.currentRound / c.maxRoundsValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.modeMostLikely),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ronda ${c.currentRound}/${c.maxRoundsValue}',
            style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DuelController c) {
    if (c.currentTask == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text('¡Sin tareas disponibles!', style: TextStyle(color: Colors.white54, fontSize: 20)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: AppColors.modeMostLikely.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, color: AppColors.modeMostLikely, size: 40),
          const SizedBox(height: 20),
          Text(
            c.currentTask!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DuelController c) {
    if (c.currentTask == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildClaimButton(
                  '${c.player1Name} lo hizo',
                  Icons.male,
                  c.player1Color,
                   c.claimHe,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClaimButton(
                  '${c.player2Name} lo hizo',
                  Icons.female,
                  c.player2Color,
                   c.claimShe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: c.skipTask,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: const Text(
                'SALTAR TAREA',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
