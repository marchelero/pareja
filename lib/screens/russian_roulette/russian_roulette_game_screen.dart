import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/russian_roulette_controller.dart';
import '../../widgets/game_winner_dialog.dart';
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
        if (c.isWildMode) {
          c.startRespin();
        } else {
          final target = (_spinController.value + 1.0 / 6.0).clamp(0.0, 50.0);
          _spinController.animateTo(
            target,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
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
    final scoreHe = c.scoreHe;
    final scoreShe = c.scoreShe;
    final TextStyle titleStyle = GoogleFonts.creepster(
      fontSize: 56,
      fontWeight: FontWeight.w400,
      color: AppColors.modeRussianRoulette,
      letterSpacing: 8,
      height: 1.1,
      shadows: [
        Shadow(color: AppColors.modeRussianRoulette.withValues(alpha: 0.8), blurRadius: 40),
        Shadow(color: Colors.black87, blurRadius: 4, offset: const Offset(2, 3)),
      ],
    );
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('DISPARO\nMORTAL', style: titleStyle, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    loserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    child: Image.asset(
                      'assets/images/tombstone.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.modeRussianRoulette.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ÉL',
                            style: TextStyle(
                              color: const Color(0xFF448AFF),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: List.generate(
                              scoreShe,
                              (_) => const Text('💀', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('†',
                          style: TextStyle(
                            color: AppColors.modeRussianRoulette.withValues(alpha: 0.4),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ELLA',
                            style: TextStyle(
                              color: const Color(0xFFFF4081),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: List.generate(
                              scoreHe,
                              (_) => const Text('💀', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      c.nextRoundAfterDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.modeRussianRoulette,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                      shadowColor: AppColors.modeRussianRoulette,
                    ),
                    child: const Text(
                      'SIGUIENTE RONDA',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  // ScoreBoard temático ruleta rusa
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.modeRussianRoulette.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ÉL',
                              style: TextStyle(
                                color: const Color(0xFF448AFF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 1,
                              runSpacing: 1,
                              children: List.generate(
                                c.scoreShe,
                                (_) => const Text('💀', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('†',
                            style: TextStyle(
                              color: AppColors.modeRussianRoulette.withValues(alpha: 0.4),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ELLA',
                              style: TextStyle(
                                color: const Color(0xFFFF4081),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 1,
                              runSpacing: 1,
                              children: List.generate(
                                c.scoreHe,
                                (_) => const Text('💀', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: c.activeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.activeColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  c.isSpinning
                      ? '⚡ GIRANDO...'
                      : 'RONDA ${c.roundNumber}  •  ${c.activeName.toUpperCase()}',
                  style: TextStyle(
                    color: c.isSpinning ? Colors.white54 : c.activeColor,
                    fontSize: c.isSpinning ? 16 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: c.isSpinning
                        ? null
                        : [Shadow(color: c.activeColor.withValues(alpha: 0.3), blurRadius: 8)],
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
                  // Destello visual al disparar (sin texto)
                  if (c.isBangResult)
                    AnimatedBuilder(
                      animation: _bangController,
                      builder: (context, _) {
                        final v = _bangController.value;
                        return IgnorePointer(
                          child: Center(
                            child: Transform.scale(
                              scale: 1.0 + v * 4.0,
                              child: Opacity(
                                opacity: (1.0 - v).clamp(0.0, 1.0),
                                child: Container(
                                  width: 140, height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.9 * (1.0 - v)),
                                        Colors.red.withValues(alpha: 0.5 * (1.0 - v)),
                                        Colors.red.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 0.3, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.4 * (1.0 - v)),
                                        blurRadius: 60,
                                        spreadRadius: 25,
                                      ),
                                    ],
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
            if (!c.isWildMode) ...[
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
            ],
            const SizedBox(height: 20),
            // Trigger button
            if (!c.isSpinning)
              _buildTriggerButton(c),
            // Pre-carga emojis y fuente Creepster para evitar retardos en diálogos
            const Text('💀🪦', style: TextStyle(fontSize: 0.1, color: Colors.transparent)),
            Text('x', style: GoogleFonts.creepster(fontSize: 0.1, color: Colors.transparent)),
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
          scale: Tween<double>(begin: 1.0, end: c.isPlaying ? 1.08 : 1.0).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 210,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  AppColors.modeRussianRoulette,
                  AppColors.modeRussianRoulette.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.modeRussianRoulette.withValues(alpha: 0.9),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.modeRussianRoulette.withValues(alpha: c.isPlaying ? 0.5 : 0.2),
                  blurRadius: 30,
                  spreadRadius: c.isPlaying ? 4 : 0,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    c.isPlaying ? Icons.gps_fixed : Icons.hourglass_empty,
                    color: Colors.white.withValues(alpha: c.isPlaying ? 1.0 : 0.5),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      c.isPlaying ? '¡DISPARAR!' : 'ESPERANDO...',
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: c.isPlaying ? 1.0 : 0.5),
                        fontSize: 18,
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
