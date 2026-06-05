import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/bomb_controller.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/round_result_dialog.dart';
import '../../widgets/score_board.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import 'bomb_start_screen.dart';
import '../games_menu_screen.dart';

class BombGameScreen extends StatefulWidget {
  final BombController controller;

  const BombGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<BombGameScreen> createState() => _BombGameScreenState();
}

class _BombGameScreenState extends State<BombGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    widget.controller.addListener(_onControllerChange);

    widget.controller.onRoundResult = ({required String loserName, required int pointsEarned}) {
      _showRoundResultDialog(loserName, pointsEarned);
    };
    widget.controller.onWinner = ({required String winnerName, required Color winnerColor}) {
      _showWinnerDialog(winnerName, winnerColor);
    };
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    widget.controller.cancelTimer();
    _pulseController.dispose();
    super.dispose();
  }

  void _showRoundResultDialog(String loserName, int pointsEarned) {
    final c = widget.controller;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return RoundResultDialog(
          loserName: loserName,
          pointsEarned: pointsEarned,
          isGoldenRound: c.isGoldenRound,
          player1Name: c.settingsProvider.player1Name,
          player2Name: c.settingsProvider.player2Name,
          scoreP1: c.scoreHe,
          scoreP2: c.scoreShe,
          onSiguienteRonda: () {
            Navigator.pop(context);
            c.nextRoundAfterDialog();
          },
        );
      },
    );
  }

  void _showWinnerDialog(String winnerName, Color winnerColor) {
    final c = widget.controller;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Bomba',
          gameColor: AppColors.modeBomb,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.settingsProvider.player1Name,
          player2Name: c.settingsProvider.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: c.scoreHe,
          scoreP2: c.scoreShe,
          maxScore: c.pointsToWin,
          isTie: false,
          onReplay: () {
            final newController = BombController(
              audioService: audioService,
              settingsProvider: settingsProvider,
              isHotMode: c.isHotMode,
              bestOf: c.bestOf,
              timerSeconds: c.timerSeconds,
              optPanic: c.optPanic,
              optGold: c.optGold,
              optWild: c.optWild,
              optAccel: c.optAccel,
            );
            newController.initGame().then((_) {
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BombGameScreen(controller: newController),
                ),
              );
            });
          },
          onGameMenu: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BombStartScreen()),
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

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Color activeColor = c.isGoldenRound ? Colors.amber : (c.isHeTurn ? Colors.blueAccent : Colors.pinkAccent);
    Color bgColor = c.isGoldenRound ? Colors.amber.withValues(alpha: 0.2) : (c.isHeTurn ? Colors.blue.withValues(alpha: 0.15) : Colors.pink.withValues(alpha: 0.15));

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: c.isPlaying ? c.passTurn : c.startGame,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [bgColor, Colors.black],
              radius: 1.5,
              center: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ScoreBoard(
                        player1Name: c.settingsProvider.player1Name,
                        player2Name: c.settingsProvider.player2Name,
                        player1Score: c.scoreHe,
                        player2Score: c.scoreShe,
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                if (c.optPanic || c.optAccel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (c.optPanic) const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.visibility_off, color: Colors.white54, size: 16)),
                        if (c.optAccel) const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.speed, color: Colors.white54, size: 16)),
                      ],
                    ),
                  ),

                const SizedBox(height: 5),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey<String>('${c.isHeTurn}-${c.isGoldenRound}'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: activeColor.withValues(alpha: 0.5), width: c.isGoldenRound ? 3 : 1),
                      boxShadow: c.isGoldenRound ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10)] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.isGoldenRound) const Icon(Icons.star, color: Colors.amber, size: 20),
                        if (c.isGoldenRound) const SizedBox(width: 5),
                        Text(
                          'TURNO DE ${c.activeName.toUpperCase()}',
                          style: TextStyle(color: activeColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                if (c.currentCategory != null) ...[
                  const Text('CATEGORÍA:', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      c.currentCategory!.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]),
                    ),
                  ),
                ],

                const Spacer(),

                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: c.isPlaying ? 1.05 : 1.0).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.isPlaying ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: c.isPlaying ? activeColor : Colors.white24, width: 4),
                      boxShadow: c.isPlaying ? [
                        BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 50, spreadRadius: 10),
                      ] : [],
                    ),
                    child: Center(
                      child: c.isPlaying
                          ? (c.optPanic
                              ? const Icon(Icons.local_fire_department, size: 120, color: Colors.redAccent)
                              : Text(
                                  '${c.timeLeft}',
                                  style: TextStyle(
                                    color: c.timeLeft <= 2 ? Colors.redAccent : Colors.white,
                                    fontSize: 100,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, size: 60, color: Colors.white),
                                SizedBox(height: 10),
                                Text('TOCAR PARA\nEMPEZAR', textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                    ),
                  ),
                ),

                const Spacer(),

                if (c.isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child                        : (c.optWild && c.activeHasWildcard)
                        ? GameButton(
                            text: 'USAR COMODÍN',
                            icon: Icons.style,
                            onPressed: c.useWildcard,
                            style: GameButtonStyle.primary,
                          )
                        : TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.5, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app, color: Colors.white70),
                                      SizedBox(width: 10),
                                      Text('TOCA LA PANTALLA PARA PASAR',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                else
                  const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
