import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pairs_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/game_help_modal.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';
import '../games_menu_screen.dart';
import 'pairs_start_screen.dart';

class PairsGameScreen extends StatefulWidget {
  final PairsController controller;
  const PairsGameScreen({super.key, required this.controller});

  @override
  State<PairsGameScreen> createState() => _PairsGameScreenState();
}

class _PairsGameScreenState extends State<PairsGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _bannerController;
  bool _showBanner = false;
  String _bannerText = '';
  int _lastRound = 0;
  bool _showingDialog = false;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lastRound = widget.controller.currentRound;
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (!mounted) return;
    final c = widget.controller;
    if (c.roundEnded && !_showingDialog) {
      _showingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showRoundEndDialog(),
      );
    }
    if (c.currentRound > _lastRound && _lastRound > 0) {
      _showBannerText('Ronda ${c.currentRound}');
    }
    _lastRound = c.currentRound;
    if (c.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
    setState(() {});
  }

  void _showRoundEndDialog() {
    final c = widget.controller;
    final isTie = c.lastRoundWinner == null;
    final isP1Winner = c.lastRoundWinner == c.player1Name;
    final Color resultColor = isTie
        ? Colors.orange
        : (isP1Winner ? c.player1Color : c.player2Color);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: resultColor.withValues(alpha: 0.5)),
        ),
        title: Text(
          isTie
              ? '¡Ronda ${c.currentRound} empatada!'
              : '${c.lastRoundWinner} ganó la ronda ${c.currentRound}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: resultColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              'R O N D A',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dialogScoreChip(
                  c.player1Name,
                  c.lastRoundP1Score,
                  c.player1Color,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _dialogScoreChip(
                  c.player2Name,
                  c.lastRoundP2Score,
                  c.player2Color,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 16),
            Text(
              'G L O B A L',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${c.player1Name}  ${c.player1Rounds} - ${c.player2Rounds}  ${c.player2Name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                _showingDialog = false;
                Navigator.pop(ctx);
                c.continueToNextRound();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: resultColor.withValues(alpha: 0.2),
                  border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'CONTINUAR',
                  style: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogScoreChip(String name, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showBannerText(String text) {
    _bannerController.forward(from: 0);
    setState(() {
      _bannerText = text;
      _showBanner = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _bannerController.reverse();
        setState(() => _showBanner = false);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _bannerController.dispose();
    super.dispose();
  }

  void _showResult() {
    final c = widget.controller;
    final int p1Rounds = c.player1Rounds;
    final int p2Rounds = c.player2Rounds;
    final bool isTie = p1Rounds == p2Rounds;
    final String winnerName = isTie
        ? 'EMPATE'
        : (p1Rounds > p2Rounds ? c.player1Name : c.player2Name);
    final Color winnerColor = isTie
        ? Colors.orange
        : (p1Rounds > p2Rounds ? c.player1Color : c.player2Color);
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Pares',
          gameColor: AppColors.modePairs,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.player1Name,
          player2Name: c.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: p1Rounds,
          scoreP2: p2Rounds,
          maxScore: c.maxRounds,
          isTie: isTie,
          onReplay: () {
            final audioService = context.read<AudioService>();
            final settings = context.read<SettingsProvider>();
            final nc = PairsController(
              audioService: audioService,
              settingsProvider: settings,
              maxRounds: c.maxRounds,
              gridRows: c.gridRows,
              gridCols: c.gridCols,
            );
            nc.initGame();
            nc.setStartingPlayer(true);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PairsGameScreen(controller: nc),
              ),
            );
          },
          onGameMenu: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PairsStartScreen()),
          ),
          onMainMenu: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const GamesMenuScreen()),
            (route) => false,
          ),
        ),
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Se muestran cartas boca abajo en una cuadr\u00edcula.'),
        GameHelpModal.step('2', 'Encuentra las parejas de cartas iguales.'),
        GameHelpModal.step('3', 'Altern\u00e1is turnos para encontrar las parejas.'),
        GameHelpModal.bullet('Encuentras una pareja', 'vuelves a jugar.', Colors.greenAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien consiga m\u00e1s parejas al final.', Colors.amberAccent, ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final screenWidth = MediaQuery.of(context).size.width;
    final cols = c.gridCols;
    final gap = 6.0;
    final cardSize = (screenWidth - 24 - gap * (cols - 1)) / cols;

    return Scaffold(
      body: Stack(
        children: [
          NeonBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(c),
                  _buildRoundInfo(c),
                  _buildTurnIndicator(c),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildGrid(c, cardSize, gap),
                    ),
                  ),
                  _buildLegend(c),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_showBanner) _buildBanner(),
        ],
      ),
    );
  }

  Widget _buildHeader(PairsController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              _scoreChip(c.player1Name, c.player1Score, c.player1Color),
              const SizedBox(width: 6),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              _scoreChip(c.player2Name, c.player2Score, c.player2Color),
            ],
          ),
          GameHelpModal.helpButton(_showHelpModal),
        ],
      ),
    );
  }

  Widget _scoreChip(String name, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundInfo(PairsController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.modePairs.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ronda ${c.currentRound}',
              style: const TextStyle(
                color: AppColors.modePairs,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${c.matchedPairs}/${c.totalPairs} pares',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(PairsController c) {
    if (c.isChecking) return const SizedBox(height: 32);

    final isP1 = c.isPlayer1Turn;
    final color = isP1 ? c.player1Color : c.player2Color;
    final name = isP1 ? c.player1Name : c.player2Name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Turno de $name',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(PairsController c, double cardSize, double gap) {
    final rows = c.gridRows;
    final cols = c.gridCols;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cols, (col) {
              final index = row * cols + col;
              if (index >= c.cards.length) {
                return SizedBox(width: cardSize, height: cardSize);
              }
              return Padding(
                padding: EdgeInsets.only(right: col < cols - 1 ? gap : 0),
                child: _buildCard(index, c, cardSize),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCard(int index, PairsController c, double size) {
    final card = c.cards[index];
    final isClickable = !card.isMatched && !c.isChecking;

    return GestureDetector(
      onTap: isClickable ? () => c.selectCard(index) : null,
      child: AnimatedOpacity(
        opacity: card.isMatched ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 400),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: (card.isFlipped || card.isMatched)
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _cardBack(size),
          secondChild: _cardFront(card.emoji, card.isMatched, size),
          layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Positioned.fill(child: bottomChild),
                  Positioned.fill(child: topChild),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cardBack(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.modePairs.withValues(alpha: 0.7),
            AppColors.modePairs.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: AppColors.modePairs.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.modePairs.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.stars_rounded,
          color: Colors.white.withValues(alpha: 0.6),
          size: size * 0.35,
        ),
      ),
    );
  }

  Widget _cardFront(String emoji, bool isMatched, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: isMatched ? 0.08 : 0.15),
        border: Border.all(
          color: isMatched
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: isMatched
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
      ),
    );
  }

  Widget _buildLegend(PairsController c) {
    final roundsP1 = c.player1Rounds;
    final roundsP2 = c.player2Rounds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundDot(c.player1Color, roundsP1 > roundsP2),
          const SizedBox(width: 6),
          Text(
            '${c.player1Name}: $roundsP1',
            style: TextStyle(
              color: c.player1Color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${c.player2Name}: $roundsP2',
            style: TextStyle(
              color: c.player2Color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          _roundDot(c.player2Color, roundsP2 > roundsP1),
        ],
      ),
    );
  }

  Widget _roundDot(Color color, bool isLeading) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isLeading
            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
            : null,
      ),
    );
  }

  Widget _buildBanner() {
    return AnimatedBuilder(
      animation: _bannerController,
      builder: (context, _) {
        final t = _bannerController.value;
        final scale = 1.0 + (1.0 - t) * 0.3;
        final opacity = t.clamp(0.0, 1.0);
        return IgnorePointer(
          child: Container(
            color: Colors.black87,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    _bannerText,
                    style: TextStyle(
                      color: AppColors.modePairs,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: AppColors.modePairs.withValues(alpha: 0.5),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
