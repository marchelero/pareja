import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/never_have_i_ever_controller.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import 'never_have_i_ever_start_screen.dart';
import '../games_menu_screen.dart';

class NeverHaveIEverGameScreen extends StatefulWidget {
  final NeverHaveIEverController controller;

  const NeverHaveIEverGameScreen({super.key, required this.controller});

  @override
  State<NeverHaveIEverGameScreen> createState() =>
      _NeverHaveIEverGameScreenState();
}

class _NeverHaveIEverGameScreenState extends State<NeverHaveIEverGameScreen>
    with SingleTickerProviderStateMixin {
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
    final isP1 = winnerName == c.player1Name;
    final Color winnerColor = isP1 ? c.player1Color : c.player2Color;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Yo Nunca',
          gameColor: AppColors.modeNeverHaveIEver,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.player1Name,
          player2Name: c.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: c.scorePlayer1,
          scoreP2: c.scorePlayer2,
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
                  builder: (context) =>
                      NeverHaveIEverGameScreen(controller: newController),
                ),
              );
            });
          },
          onGameMenu: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NeverHaveIEverStartScreen(),
              ),
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
                  colors: [Colors.deepPurple.shade900, Colors.purple.shade900],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.pinkAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
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
                    'PENITENCIA',
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
                    child: GameButton(
                      text: 'ACEPTAR',
                      icon: Icons.check,
                      onPressed: () {
                        c.clearPenance();
                        _showingPenance = false;
                        Navigator.pop(context);
                      },
                      style: GameButtonStyle.primary,
                      height: 55,
                      customColor: Colors.pinkAccent,
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

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Se muestra una pregunta.'),
        GameHelpModal.step('2', 'Cada jugador responde por turno:'),
        GameHelpModal.bullet('SI', 'SI, LO HE HECHO', Colors.greenAccent, 'lo has hecho'),
        GameHelpModal.bullet('NO', 'NUNCA', Colors.orangeAccent, 'nunca lo has hecho'),
        GameHelpModal.step('3', 'RESULTADO:'),
        GameHelpModal.bullet(null, 'Si uno dice SI y el otro NO', Colors.orangeAccent, 'el que dijo NO gana 1 punto'),
        GameHelpModal.bullet(null, 'Si ambos dicen igual', Colors.grey, 'nadie gana puntos'),
        GameHelpModal.step('4', '3 strikes = penitencia'),
      ],
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

    final bool isP1Turn = !c.player1Answered;
    final bool isP2Turn = c.player1Answered && !c.player2Answered;
    final bool isRevealPhase = c.phaseReadyToReveal && !c.isRevealed;
    final bool isResultPhase = c.isRevealed;

    final Color phaseColor = isP1Turn
        ? c.player1Color
        : (isP2Turn ? c.player2Color : Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _NeonBgWrapper(
        phaseColor: phaseColor,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildScoreChip(c.player1Name, c.scorePlayer1, c.player1Color),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                        _buildScoreChip(c.player2Name, c.scorePlayer2, c.player2Color),
                      ],
                    ),
                    const Spacer(),
                    GameHelpModal.helpButton(_showHelpModal),
                  ],
                ),
              ),

              Text(
                'RONDA ${c.roundNumber} de ${c.rounds}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStrikeDisplay(
                    c.player1Name,
                    c.strikesPlayer1,
                    c.strikesForPenance,
                    c.player1Color,
                  ),
                  const SizedBox(width: 40),
                  _buildStrikeDisplay(
                    c.player2Name,
                    c.strikesPlayer2,
                    c.strikesForPenance,
                    c.player2Color,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isP1Turn
                      ? 'TURNO DE ${c.player1Name.toUpperCase()}'
                      : (isP2Turn
                            ? 'TURNO DE ${c.player2Name.toUpperCase()}'
                            : (isRevealPhase
                                  ? 'LISTO PARA REVELAR'
                                  : 'RESULTADO')),
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
                    'NUNCA HAS...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      '${c.currentQuestion!.text}?',
                      key: ValueKey<String>(
                        '${c.roundNumber}-${c.currentQuestion!.id}',
                      ),
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

              const SizedBox(height: 24),

              if (isResultPhase && c.isRevealed) ...[_buildResultDisplay(c)],

              const Spacer(),

              if (isP1Turn) ...[
                _buildAnswerButtons(player: 1),
              ] else if (isP2Turn) ...[
                _buildAnswerButtons(player: 2),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 10,
                  ),
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

  Widget _buildAnswerButtons({required int player}) {
    final c = widget.controller;
    final Color accentColor = player == 1 ? c.player1Color : c.player2Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 64,
            child: GameButton(
              text: 'SI, LO HE HECHO',
              icon: Icons.thumb_up_alt_outlined,
              onPressed: () {
                c.audioService.playClick();
                if (player == 1) {
                  c.answerPlayer1(true);
                } else {
                  c.answerPlayer2(true);
                }
              },
              style: GameButtonStyle.primary,
              customColor: accentColor,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: GameButton(
              text: 'NO, NUNCA',
              icon: Icons.block_outlined,
              onPressed: () {
                c.audioService.playClick();
                if (player == 1) {
                  c.answerPlayer1(false);
                } else {
                  c.answerPlayer2(false);
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
              'Ambos respondieron igual',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Nadie gana puntos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final String winnerName = c.strikePlayerName == c.player1Name
        ? c.player2Name
        : c.player1Name;
    final Color winnerColor = winnerName == c.player1Name
        ? c.player1Color
        : c.player2Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 36),
          const SizedBox(height: 8),
          Text(
            '$winnerName gana 1 punto',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: winnerColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Strike para ${c.strikePlayerName}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${c.player1Name} dijo ${c.player1SaidYes == true ? "SI (lo hizo)" : "NO (nunca)"}  \n'
            '${c.player2Name} dijo ${c.player2SaidYes == true ? "SI (lo hizo)" : "NO (nunca)"}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrikeDisplay(
    String name,
    int strikes,
    int maxStrikes,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          Text(name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text('$score', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _NeonBgWrapper extends StatelessWidget {
  final Color phaseColor;
  final Widget child;

  const _NeonBgWrapper({required this.phaseColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [phaseColor.withValues(alpha: 0.12), Colors.black],
          radius: 1.5,
          center: Alignment.center,
        ),
      ),
      child: child,
    );
  }
}
