import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/russian_roulette_controller.dart';
import '../../widgets/game_winner_dialog.dart';
import '../../widgets/round_result_dialog.dart';
import '../../widgets/score_board.dart';
import '../../core/theme/app_colors.dart';

class RussianRouletteGameScreen extends StatefulWidget {
  final RussianRouletteController controller;

  const RussianRouletteGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<RussianRouletteGameScreen> createState() => _RussianRouletteGameScreenState();
}

class _RussianRouletteGameScreenState extends State<RussianRouletteGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _bangController;

  late Animation<double> _shakeAnimation;

  bool _wasClickResult = false;
  bool _wasPullingTrigger = false;

  static const double _drumSize = 200.0;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      upperBound: 50.0,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bangController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    );

    widget.controller.addListener(_onControllerChange);

    widget.controller.onRoundResult = ({required String loserName}) {
      _showRoundResultDialog(loserName);
    };
    widget.controller.onWinner = ({required String winnerName, required Color winnerColor}) {
      _showWinnerDialog(winnerName, winnerColor);
    };

    // initGame() already ran before mount; sync state manually
    WidgetsBinding.instance.addPostFrameCallback((_) => _onControllerChange());
  }

  void _onControllerChange() {
    if (!mounted) return;
    final c = widget.controller;
    if (c.isSpinning) {
      if (_spinController.isAnimating) return;
      final offset = (6 - c.firingPinChamber) % 6 / 6.0;
      _spinController.value = offset;
      _spinController.addStatusListener(_onSpinComplete);
      final fullTurns = 3 + math.Random().nextInt(3);
      _spinController.animateTo(
        fullTurns + offset,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
      );
    }
    if (c.isPullingTrigger && !_wasPullingTrigger) {
      _shakeController.forward(from: 0);
    }
    if (c.isClickResult && !_wasClickResult) {
      _shakeController.reverse();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        final target = (_spinController.value + 1.0 / 6.0).clamp(0.0, 50.0);
        _spinController.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
    if (c.isBangResult) {
      _bangController.forward(from: 0);
    }
    _wasClickResult = c.isClickResult;
    _wasPullingTrigger = c.isPullingTrigger;
    setState(() {});
  }

  void _onSpinComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _spinController.removeStatusListener(_onSpinComplete);
      if (mounted) widget.controller.endSpin();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _spinController.removeStatusListener(_onSpinComplete);
    _spinController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _bangController.dispose();
    super.dispose();
  }

  void _showRoundResultDialog(String loserName) {
    final c = widget.controller;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return RoundResultDialog(
          loserName: loserName,
          pointsEarned: 1,
          isGoldenRound: false,
          heName: c.settingsProvider.heName,
          sheName: c.settingsProvider.sheName,
          scoreHe: c.scoreHe,
          scoreShe: c.scoreShe,
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return GameWinnerDialog(
          winnerName: winnerName,
          winnerColor: winnerColor,
          heName: c.settingsProvider.heName,
          sheName: c.settingsProvider.sheName,
          scoreHe: c.scoreHe,
          scoreShe: c.scoreShe,
          pointsToWin: c.pointsToWin,
          onVolverAlMenu: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Flexible(
                    child: ScoreBoard(
                      player1Name: c.settingsProvider.heName,
                      player2Name: c.settingsProvider.sheName,
                      player1Score: c.scoreHe,
                      player2Score: c.scoreShe,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<String>('${c.isHeTurn}-${c.roundNumber}'),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: c.activeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.activeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  c.isSpinning
                      ? 'GIRANDO...'
                      : 'RONDA ${c.roundNumber} • TURNO DE ${c.activeName.toUpperCase()}',
                  style: TextStyle(
                    color: c.isSpinning ? Colors.white54 : c.activeColor,
                    fontSize: c.isSpinning ? 14 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: _drumSize + 40,
              height: _drumSize + 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Drum with chambers (CustomPainter for precise rendering)
                  ListenableBuilder(
                    listenable: Listenable.merge([_spinController, widget.controller]),
                    builder: (context, _) {
                      final cc = widget.controller;
                      return CustomPaint(
                        size: const Size(_drumSize, _drumSize),
                        painter: _DrumPainter(
                          turns: _spinController.value,
                          checkedOrder: cc.checkedOrder,
                          currentChamber: cc.currentChamber,
                          bulletFired: cc.bulletFired,
                          isSpinning: cc.isSpinning,
                        ),
                      );
                    },
                  ),
                  // Firing pin
                  Positioned(
                    top: -15,
                    child: Icon(
                      Icons.arrow_drop_up,
                      color: c.isPlaying
                          ? AppColors.modeRussianRoulette
                          : Colors.white38,
                      size: 45,
                    ),
                  ),
                  // Baaam overlay on drum
                  if (c.isBangResult)
                    AnimatedBuilder(
                      animation: _bangController,
                      builder: (context, _) {
                        final value = _bangController.value;
                        final opacity = (1.0 - value).clamp(0.0, 1.0);
                        final scale = 1.0 + value * 2.5;
                        return IgnorePointer(
                          child: Center(
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withValues(alpha: 0.5 * opacity),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.3 * opacity),
                                        blurRadius: 50,
                                        spreadRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Baam',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: opacity),
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        shadows: [
                                          Shadow(color: Colors.red, blurRadius: 40),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Shooting history
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final checked = i < c.checkedOrder.length;
                final chamberIndex = checked ? c.checkedOrder[i] : -1;
                final wasBullet = c.bulletFired && chamberIndex == c.currentChamber;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: wasBullet
                        ? Colors.redAccent
                        : (checked ? Colors.greenAccent : Colors.white.withValues(alpha: 0.2)),
                    border: Border.all(
                      color: wasBullet
                          ? Colors.red
                          : (checked ? Colors.greenAccent : Colors.white24),
                      width: checked ? 2 : 1,
                    ),
                  ),
                  child: checked
                      ? Center(
                          child: Text(
                            '${chamberIndex + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),
            const SizedBox(height: 20),
            // Trigger button
            if (!c.isSpinning)
              _buildTriggerButton(c),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerButton(RussianRouletteController c) {
    Widget button = GestureDetector(
      onTap: c.isPlaying ? () => c.pullTrigger() : null,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shakeX = math.sin(_shakeAnimation.value * 40) * 4;
          final shakeY = math.cos(_shakeAnimation.value * 30) * 3;
          return Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: child,
          );
        },
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: c.isPlaying ? 1.05 : 1.0).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  AppColors.modeRussianRoulette,
                  AppColors.modeRussianRoulette.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.modeRussianRoulette.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.modeRussianRoulette.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gps_fixed,
                    color: Colors.white.withValues(alpha: c.isPlaying ? 1.0 : 0.5),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      c.isPlaying ? '¡DISPARAR!' : 'ESPERANDO...',
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: c.isPlaying ? 1.0 : 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return button;
  }
}

class _DrumPainter extends CustomPainter {
  final double turns;
  final List<int> checkedOrder;
  final int currentChamber;
  final bool bulletFired;
  final bool isSpinning;

  _DrumPainter({
    required this.turns,
    required this.checkedOrder,
    required this.currentChamber,
    required this.bulletFired,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final drumRadius = size.width / 2;
    const chamberOrbit = 70.0;
    const chamberSize = 34.0;
    const chamberRadius = chamberSize / 2;

    // Drum body (fixed, not rotating)
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, drumRadius, fill);

    // Drum glow
    if (isSpinning) {
      final glow = Paint()
        ..color = AppColors.modeRussianRoulette.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(center, drumRadius, glow);
    }

    // Drum border
    final border = Paint()
      ..color = isSpinning
          ? AppColors.modeRussianRoulette.withValues(alpha: 0.8)
          : Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSpinning ? 4.0 : 3.0;
    canvas.drawCircle(center, drumRadius, border);

    // Chambers (rotating as a group)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * math.pi);

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0 - 90.0) * (math.pi / 180.0);
      final cx = chamberOrbit * math.cos(angle);
      final cy = chamberOrbit * math.sin(angle);
      final pos = Offset(cx, cy);

      final fired = checkedOrder.contains(i);
      final wasBullet = bulletFired && i == currentChamber;

      Color baseColor;
      double alpha;
      if (wasBullet) {
        baseColor = Colors.red;
        alpha = 1.0;
      } else if (fired) {
        baseColor = Colors.greenAccent;
        alpha = 0.7;
      } else {
        baseColor = Colors.grey;
        alpha = 0.35;
      }

      final isLatest = fired && !wasBullet && checkedOrder.isNotEmpty && checkedOrder.last == i;

      // Chamber fill
      final fillPaint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, chamberRadius, fillPaint);

      // Chamber border
      final borderPaint = Paint()
        ..color = isLatest ? Colors.white : baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLatest ? 2.5 : 1.5;
      canvas.drawCircle(pos, chamberRadius, borderPaint);

      // White dot for fired chambers (latest one has glow)
      if (fired && !wasBullet) {
        final dotPaint = Paint()
          ..color = Colors.white.withValues(alpha: isLatest ? 0.9 : 0.6);
        canvas.drawCircle(pos, chamberRadius * 0.35, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrumPainter oldDelegate) => true;
}
