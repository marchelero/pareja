import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/memory_controller.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/neon_background.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import 'memory_start_screen.dart';
import '../games_menu_screen.dart';

class MemoryGameScreen extends StatefulWidget {
  final MemoryController controller;
  const MemoryGameScreen({super.key, required this.controller});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _successFlashController;
  bool _showRoundBanner = false;
  String _roundBannerText = '';
  final List<AnimationController> _flashControllers = [];
  int _prevLevel = 1;

  static const _buttonColors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.amberAccent,
  ];

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _successFlashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    for (int i = 0; i < 4; i++) {
      _flashControllers.add(AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ));
    }

    widget.controller.addListener(_onControllerChange);
    widget.controller.onGameFinished = ({required String winnerName, required String loserName}) {
      _showResult(winnerName, loserName);
    };
    widget.controller.onRoundLost = ({required String loserName}) {
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showRoundLost(loserName);
      });
    };

  }

  void _onControllerChange() {
    if (!mounted) return;

    final c = widget.controller;
    if (c.currentLevel > _prevLevel) {
      _successFlashController.forward(from: 0);
    }
    _prevLevel = c.currentLevel;
    setState(() {});
  }

  void _onTap(int index) {
    final c = widget.controller;
    if (!c.isPlayerTurn) return;

    _flashControllers[index].forward().then((_) {
      if (mounted) _flashControllers[index].reverse();
    });
    c.playerTap(index);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _shakeController.dispose();
    _successFlashController.dispose();
    for (final c in _flashControllers) { c.dispose(); }
    super.dispose();
  }

  void _showRoundLost(String loserName) {
    final c = widget.controller;
    final bool heLost = loserName == c.player1Name;
    final String winnerName = heLost ? c.player2Name : c.player1Name;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5))),
        title: const Text('¡ERROR!', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$loserName se equivocó', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Text('Punto para $winnerName', textAlign: TextAlign.center, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (c.isGameOver) return;
                setState(() {
                  _showRoundBanner = true;
                  _roundBannerText = 'Ronda ${c.currentRound + 1}';
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() => _showRoundBanner = false);
                    c.startNextRound();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Text('CONTINUAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResult(String winnerName, String loserName) {
    final c = widget.controller;
    final bool isHe = winnerName == c.player1Name;
    final Color winnerColor = isHe ? c.player1Color : c.player2Color;
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => GameResultScreen(
        gameName: 'Memoria',
        gameColor: AppColors.modeMemory,
        winnerName: winnerName,
        winnerColor: winnerColor,
        player1Name: c.player1Name, player2Name: c.player2Name,
        player1Icon: settingsProvider.player1Icon,
        player2Icon: settingsProvider.player2Icon,
        player1Color: c.player1Color,
        player2Color: c.player2Color,
        scoreP1: c.player1Score, scoreP2: c.player2Score,
        maxScore: c.maxRoundsValue,
        isTie: winnerName == 'EMPATE',
        onReplay: () {
          final audioService = context.read<AudioService>();
          final settingsProvider = context.read<SettingsProvider>();
          final nc = MemoryController(audioService: audioService, settingsProvider: settingsProvider, maxRounds: c.maxRoundsValue);
          nc.initGame().then((_) {
            if (!context.mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MemoryGameScreen(controller: nc)));
          });
        },
        onGameMenu: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemoryStartScreen())),
        onMainMenu: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GamesMenuScreen()), (route) => false),
      ),
    ));
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Se ilumina una secuencia de colores.'),
        GameHelpModal.step('2', 'Repite la secuencia tocando los botones en el mismo orden.'),
        GameHelpModal.step('3', 'Cada ronda a\u00f1ade un color m\u00e1s. Si fallas, pierdes la ronda.'),
        GameHelpModal.bullet('Pierde la ronda', 'quien falle al repetir la secuencia.', Colors.redAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien gane m\u00e1s rondas.', Colors.greenAccent, ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final screenWidth = MediaQuery.of(context).size.width;
    final btnSize = (screenWidth - 60) / 2;

    return Scaffold(
      body: Stack(
        children: [
          NeonBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(c),
                  const SizedBox(height: 4),
                  _buildProgress(c),
                  const SizedBox(height: 8),
                  _buildTurnInfo(c),
                  const SizedBox(height: 4),
                  _buildCountdown(c),
                  const Spacer(),
                  _buildGrid(c, btnSize),
                  const Spacer(),
                  _buildInputProgress(c),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_showRoundBanner) _buildRoundBanner(),
          _buildSuccessFlash(),
        ],
      ),
    );
  }

  Widget _buildRoundBanner() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, _) {
            return Transform.scale(
              scale: 1.0 + (1.0 - _shakeController.value) * 0.5,
              child: Text(
                _roundBannerText,
                style: TextStyle(
                  color: AppColors.modeMemory,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  shadows: [Shadow(color: AppColors.modeMemory.withValues(alpha: 0.6), blurRadius: 30)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessFlash() {
    return AnimatedBuilder(
      animation: _successFlashController,
      builder: (context, _) {
        final opacity = _successFlashController.value;
        if (opacity <= 0) return const SizedBox.shrink();
        return IgnorePointer(
          child: Container(
            color: Colors.greenAccent.withValues(alpha: opacity * 0.15),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MemoryController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 30), onPressed: () => Navigator.pop(context)),
          Row(
            children: [
              _scoreChip(c.player1Name, c.player1Score, c.player1Color),
              const SizedBox(width: 6),
              const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 12)),
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
          Text(name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text('$score', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildProgress(MemoryController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.modeMemory.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Nivel ${c.currentLevel}', style: const TextStyle(color: AppColors.modeMemory, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          const Spacer(),
          Text('Ronda ${c.currentRound}/${c.maxRoundsValue}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTurnInfo(MemoryController c) {
    Widget info;
    if (c.isTransitioning) {
      info = Column(
        key: const ValueKey('transition'),
        children: [
          Text(c.activeName.toUpperCase(), style: TextStyle(color: c.isHeTurn ? c.player1Color : c.player2Color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text('SIGUIENTE', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
        ],
      );
    } else if (c.isShowingSequence) {
      info = Column(
        key: const ValueKey('memorize'),
        children: [
          const Text('¡MEMORIZA!', style: TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 5)),
          const SizedBox(height: 4),
          Text(c.activeName.toUpperCase(), style: TextStyle(color: c.isHeTurn ? c.player1Color : c.player2Color, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
        ],
      );
    } else if (c.isPlayerTurn) {
      info = Column(
        key: const ValueKey('repeat'),
        children: [
          Text('${c.activeName.toUpperCase()} — REPITE', style: TextStyle(color: c.isHeTurn ? c.player1Color : c.player2Color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 4),
          Text('${c.inputIndex}/${c.sequence.length}', style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );
    } else {
      info = const SizedBox(key: ValueKey('empty'), height: 48);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: info,
    );
  }

  Widget _buildCountdown(MemoryController c) {
    if (!c.isPlayerTurn) return const SizedBox(height: 8);

    final fraction = c.timeLeft / 3.0;
    final color = fraction > 0.5 ? Colors.greenAccent : (fraction > 0.25 ? Colors.amberAccent : Colors.redAccent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${c.timeLeft.toStringAsFixed(1)}s', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGrid(MemoryController c, double size) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, _) {
        final shake = _shakeController.value;
        final offset = shake > 0
            ? sin(shake * pi * 4) * (1 - shake) * 24.0
            : 0.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildButton(0, size, c),
                    const SizedBox(width: 12),
                    _buildButton(1, size, c),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildButton(2, size, c),
                    const SizedBox(width: 12),
                    _buildButton(3, size, c),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(int index, double size, MemoryController c) {
    final Color baseColor = _buttonColors[index];
    final bool isHighlighted = c.highlightedButton == index;
    final bool isInputPhase = c.isPlayerTurn;

    return GestureDetector(
      onTap: isInputPhase ? () => _onTap(index) : null,
      child: AnimatedBuilder(
        animation: _flashControllers[index],
        builder: (context, _) {
          final flash = _flashControllers[index].value;
          final bool bright = isHighlighted || flash > 0;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: bright ? Colors.white : baseColor.withValues(alpha: 0.6),
              border: Border.all(
                color: bright ? Colors.white : baseColor.withValues(alpha: 0.8),
                width: bright ? 4 : 2,
              ),
              boxShadow: [
                if (bright)
                  BoxShadow(color: baseColor.withValues(alpha: 0.9), blurRadius: 40, spreadRadius: 10)
                else
                  BoxShadow(color: baseColor.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: bright
                ? const Icon(Icons.lightbulb, color: Colors.white, size: 40)
                : isInputPhase
                    ? Icon(Icons.touch_app, color: Colors.white.withValues(alpha: 0.5), size: 32)
                    : null,
          );
        },
      ),
    );
  }

  Widget _buildInputProgress(MemoryController c) {
    if (!c.isPlayerTurn && !c.isShowingSequence) {
      return const SizedBox(height: 30);
    }
    return const SizedBox(height: 30);
  }
}
