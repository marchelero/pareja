import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/never_have_i_ever_controller.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/score_board.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import 'never_have_i_ever_start_screen.dart';
import '../games_menu_screen.dart';

class NeverHaveIEverGameScreen extends StatefulWidget {
  final NeverHaveIEverController controller;

  const NeverHaveIEverGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<NeverHaveIEverGameScreen> createState() => _NeverHaveIEverGameScreenState();
}

class _NeverHaveIEverGameScreenState extends State<NeverHaveIEverGameScreen> with SingleTickerProviderStateMixin {
  bool _showingPenance = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);

    widget.controller.onWinner = (String winnerName) {
      _showWinnerDialog(winnerName);
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

  void _showWinnerDialog(String winnerName) {
    final c = widget.controller;
    final isHe = winnerName == c.player1Name;
    final Color winnerColor = isHe ? c.player1Color : c.player2Color;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Yo Nunca',
          gameColor: AppColors.modeMostLikely,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.player1Name,
          player2Name: c.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: c.scoreHe,
          scoreP2: c.scoreShe,
          maxScore: c.pointsToWin,
          isTie: false,
          onReplay: () {
            final newController = NeverHaveIEverController(
              audioService: audioService,
              settingsProvider: settingsProvider,
              rounds: c.rounds,
              pointsToWin: c.pointsToWin,
              strikesForPenance: c.strikesForPenance,
              isHotMode: c.isHotMode,
            );
            newController.initGame().then((_) {
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NeverHaveIEverGameScreen(controller: newController),
                ),
              );
            });
          },
          onGameMenu: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NeverHaveIEverStartScreen()),
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

  void _showPenanceDialog() {
    _showingPenance = true;
    final c = widget.controller;

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
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade900,
                    Colors.purple.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 60, color: Colors.amber),
                  const SizedBox(height: 15),
                  const Text(
                    '\u{26A1} PENITENCIA \u{26A1}',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    c.penanceText ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        c.clearPenance();
                        _showingPenance = false;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
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

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (c.penanceText != null && !_showingPenance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c.penanceText != null && !_showingPenance) {
          _showPenanceDialog();
        }
      });
    }

    final bool isHePhase = !c.heAnswered;
    final bool isShePhase = c.heAnswered && !c.sheAnswered;
    final bool isRevealPhase = c.phaseReadyToReveal && !c.isRevealed;
    final bool isResultPhase = c.isRevealed;

    final Color phaseColor = isHePhase
        ? c.player1Color
        : (isShePhase ? c.player2Color : Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: NeonBgWrapper(
        phaseColor: phaseColor,
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
                      player1Name: c.player1Name,
                      player2Name: c.player2Name,
                      player1Score: c.scoreHe,
                      player2Score: c.scoreShe,
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Text(
                'RONDA ${c.roundNumber} de ${c.rounds}',
                style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStrikeDisplay(c.player1Name, c.strikesHe, c.strikesForPenance, c.player1Color),
                  const SizedBox(width: 40),
                  _buildStrikeDisplay(c.player2Name, c.strikesShe, c.strikesForPenance, c.player2Color),
                ],
              ),

              const SizedBox(height: 20),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isHePhase
                      ? 'TURNO DE ${c.player1Name.toUpperCase()}'
                      : (isShePhase
                          ? 'TURNO DE ${c.player2Name.toUpperCase()}'
                          : (isRevealPhase ? 'LISTO PARA REVELAR' : 'RESULTADO')),
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (c.currentQuestion != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Nunca he...',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      '${c.currentQuestion!.text}?',
                      key: ValueKey<String>('${c.roundNumber}-${c.currentQuestion!.id}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              if (isResultPhase && c.isRevealed) ...[
                _buildResultDisplay(c),
              ],

              const Spacer(),

              if (isHePhase) ...[
                _buildAnswerButtons(phase: 'he'),
              ] else if (isShePhase) ...[
                _buildAnswerButtons(phase: 'she'),
              ] else if (isRevealPhase) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GameButton(
                    text: 'REVELAR',
                    icon: Icons.remove_red_eye,
                    onPressed: () {
                      c.audioService.playClick();
                      c.reveal();
                    },
                    style: GameButtonStyle.primary,
                  ),
                ),
              ] else if (isResultPhase) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: GameButton(
                    text: 'SIGUIENTE RONDA',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      c.audioService.playClick();
                      c.nextRound();
                    },
                    style: GameButtonStyle.primary,
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButtons({required String phase}) {
    final c = widget.controller;
    final Color accentColor = phase == 'he' ? c.player1Color : c.player2Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: GameButton(
              text: '\u{1F44A} \u{A1}YO!',
              onPressed: () {
                c.audioService.playClick();
                if (phase == 'he') {
                  c.answerHe(true);
                } else {
                  c.answerShe(true);
                }
              },
              style: GameButtonStyle.primary,
              customColor: accentColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GameButton(
              text: '\u{1F645} NUNCA',
              onPressed: () {
                c.audioService.playClick();
                if (phase == 'he') {
                  c.answerHe(false);
                } else {
                  c.answerShe(false);
                }
              },
              style: GameButtonStyle.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay(NeverHaveIEverController c) {
    if (!c.disparity) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
            SizedBox(height: 8),
            Text(
              '+1 punto para cada uno \u{2705}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 40),
          const SizedBox(height: 8),
          Text(
            '\u{26A1} Strike para ${c.strikePlayerName}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '${c.player1Name} dijo ${c.heSaidYo == true ? "YO" : "NUNCA"} \u{b7} ${c.player2Name} dijo ${c.sheSaidYo == true ? "YO" : "NUNCA"}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStrikeDisplay(String name, int strikes, int maxStrikes, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxStrikes, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < strikes ? Icons.bolt : Icons.bolt_outlined,
                color: i < strikes ? Colors.amber : Colors.white24,
                size: 20,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class NeonBgWrapper extends StatelessWidget {
  final Color phaseColor;
  final Widget child;

  const NeonBgWrapper({
    super.key,
    required this.phaseColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            phaseColor.withValues(alpha: 0.12),
            Colors.black,
          ],
          radius: 1.5,
          center: Alignment.center,
        ),
      ),
      child: child,
    );
  }
}
