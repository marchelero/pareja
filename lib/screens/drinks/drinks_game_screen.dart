import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/drinks_controller.dart';
import '../../core/models/drink_task.dart';
import '../../widgets/game_result_screen.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import 'drinks_start_screen.dart';
import '../games_menu_screen.dart';

class DrinksGameScreen extends StatefulWidget {
  final DrinksController controller;

  const DrinksGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DrinksGameScreen> createState() => _DrinksGameScreenState();
}

class _DrinksGameScreenState extends State<DrinksGameScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);

    widget.controller.onGameOver = (String playerName) {
      _showContinueDialog(playerName);
    };
    widget.controller.onGameFinished = (String playerName) {
      _showResultScreen(playerName);
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

  void _showContinueDialog(String playerName) {
    final c = widget.controller;
    final bool isHe = playerName == c.player1Name;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.pink.withValues(alpha: 0.3), Colors.black],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isHe ? c.player1Color : c.player2Color).withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                    border: Border.all(
                      color: (isHe ? c.player1Color : c.player2Color).withValues(alpha: 0.6),
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      isHe ? (c.settingsProvider.player1Gender == PlayerGender.male ? 'assets/images/man_drinking.png' : 'assets/images/woman_drinking.png') : (c.settingsProvider.player2Gender == PlayerGender.male ? 'assets/images/man_drinking.png' : 'assets/images/woman_drinking.png'),
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡${playerName.toUpperCase()} SECO!',
                  style: TextStyle(
                    color: isHe ? c.player1Color : c.player2Color,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${c.player1Name}: ${c.heGlassesDrunk} vaso${c.heGlassesDrunk == 1 ? '' : 's'}  •  ${c.player2Name}: ${c.sheGlassesDrunk} vaso${c.sheGlassesDrunk == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 250,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      c.resetPlayerGlasses(playerName);
                      c.advanceAfterGameOver();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('SIGUIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResultScreen(String winnerName) {
    final c = widget.controller;
    final bool isHe = winnerName == c.player1Name;
    final Color winnerColor = isHe ? c.player1Color : c.player2Color;
    final audioService = context.read<AudioService>();
    final settingsProvider = context.read<SettingsProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          gameName: 'Chupitos',
          gameColor: AppColors.modeDrinks,
          winnerName: winnerName,
          winnerColor: winnerColor,
          player1Name: c.player1Name,
          player2Name: c.player2Name,
          player1Icon: settingsProvider.player1Icon,
          player2Icon: settingsProvider.player2Icon,
          player1Color: c.player1Color,
          player2Color: c.player2Color,
          scoreP1: c.heGlassesDrunk,
          scoreP2: c.sheGlassesDrunk,
          maxScore: c.totalGlasses,
          isTie: false,
          onReplay: () {
            final newController = DrinksController(
              audioService: audioService,
              settingsProvider: settingsProvider,
              sipsPerGlass: c.sipsPerGlass,
              initialLevel: c.initialLevel,
              levelingSpeed: c.levelingSpeed,
              isHotMode: c.isHotMode,
              freeMode: c.freeMode,
              totalGlasses: c.totalGlasses,
            );
            newController.initGame().then((_) {
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DrinksGameScreen(controller: newController),
                ),
              );
            });
          },
          onGameMenu: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DrinksStartScreen()),
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

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    _buildHeader(c),
                    const SizedBox(height: 20),
                    _buildGlassesArea(c),
                    const Spacer(),
                    if (c.currentTask != null) _buildTaskCard(c),
                    const Spacer(),
                    _buildActionButtons(c),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DrinksController c) {
    double progress = (c.turnCount % c.levelingSpeed) / c.levelingSpeed;
    if (c.turnCount > 0 && c.turnCount % c.levelingSpeed == 0) progress = 1.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('NIVEL ${c.currentLevel}', style: TextStyle(color: c.currentLevel >= 5 ? Colors.orangeAccent : Colors.amberAccent, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          if (c.isHotMode) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 16),
                          ],
                        ],
                      ),
                      Text('Turno ${c.turnCount}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      if (!c.freeMode) const SizedBox(height: 4),
                      if (!c.freeMode)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.player1Color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${c.player1Name}: ${c.heGlassesDrunk}', style: TextStyle(color: c.player1Color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.player2Color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${c.player2Name}: ${c.sheGlassesDrunk}', style: TextStyle(color: c.player2Color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text('/ ${c.totalGlasses}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    c.currentLevel >= 5 ? Colors.deepOrangeAccent : Colors.orangeAccent,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassesArea(DrinksController c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGlass(c.player1Name, c.heSipsLeft, c.player1Color, c.sipsPerGlassParam),
        _buildGlass(c.player2Name, c.sheSipsLeft, c.player2Color, c.sipsPerGlassParam),
      ],
    );
  }

  Widget _buildGlass(String name, int sipsLeft, Color color, int sipsPerGlass) {
    double fillPercent = sipsLeft / sipsPerGlass;
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 220,
          child: ShotGlassWidget(
            fillPercent: fillPercent,
            color: color,
          ),
        ),
        const SizedBox(height: 15),
        Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        Text('$sipsLeft sorbos', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _getTargetText(DrinksController c) {
    if (c.currentTask == null) return '';
    if (c.currentTask!.target == DrinkTarget.both) return 'PARA: AMBOS';
    if (c.activePlayerName != null) {
      if (c.currentTask!.category == DrinkCategory.question) return 'PREGUNTA PARA: ${c.activePlayerName!.toUpperCase()}';
      if (c.currentTask!.category == DrinkCategory.challenge) return 'RETO PARA: ${c.activePlayerName!.toUpperCase()}';
      if (c.currentTask!.category == DrinkCategory.punishment) return 'CASTIGO PARA: ${c.activePlayerName!.toUpperCase()}';
      if (c.currentTask!.category == DrinkCategory.decision) return 'DECISIÓN DE: ${c.activePlayerName!.toUpperCase()}';
      return 'PARA: ${c.activePlayerName!.toUpperCase()}';
    }
    return '';
  }

  Widget _buildTaskCard(DrinksController c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: (c.currentTask!.isHot ? Colors.pink : Colors.deepPurple).withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          if (c.currentTask!.isHot)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.whatshot, color: Colors.pink, size: 20),
                SizedBox(width: 5),
                Text('MODO HOT', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
              ],
            ),
          if (_getTargetText(c).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.currentTask!.target == DrinkTarget.both
                      ? Colors.amber.withValues(alpha: 0.8)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                  border: c.currentTask!.target == DrinkTarget.both
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                ),
                child: Text(
                  _getTargetText(c),
                  style: TextStyle(
                    color: c.currentTask!.target == DrinkTarget.both ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 15),
          Text(
            c.currentTask!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            _getCategoryLabel(c.currentTask!.category),
            style: TextStyle(color: Colors.amber.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          if (c.currentTask!.sips > 0 && c.currentTask!.sips != 99)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_bar, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${c.currentTask!.sips} ${c.currentTask!.sips == 1 ? 'SORBO' : 'SORBOS'}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DrinksController c) {
    if (c.currentTask == null) return const SizedBox();

    final target = c.currentTask!.target;
    final type = c.currentTask!.type;

    if (target == DrinkTarget.both) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildDrinkButton(
              c.currentTask!.sips == 99 ? '¡TOMAR TODO EL VASO!' : '¡TOMAMOS AMBOS!',
              () {
                c.applySips(DrinkTarget.both, c.currentTask!.sips);
                c.nextTurnFromUI();
              },
              Colors.amber,
              isLarge: true,
            ),
            const SizedBox(height: 10),
            _buildDrinkButton('NADIE / NO APLICA', () {
              c.nextTurnFromUI();
            }, Colors.white10),
          ],
        ),
      );
    }

    if (type == DrinkType.game) {
      String sipsText = c.currentTask!.sips > 0 ? ' (${c.currentTask!.sips})' : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildDrinkButton('TOMA ${c.player1Name}$sipsText', () {
                c.applySips(DrinkTarget.he, c.currentTask!.sips);
                c.nextTurnFromUI();
              }, c.player1Color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDrinkButton('TOMA ${c.player2Name}$sipsText', () {
                c.applySips(DrinkTarget.she, c.currentTask!.sips);
                c.nextTurnFromUI();
              }, c.player2Color),
            ),
          ],
        ),
      );
    }

    if (target == DrinkTarget.he || target == DrinkTarget.she ||
       ((target == DrinkTarget.random || target == DrinkTarget.loser) && c.activePlayerName != null)) {
      bool isHe = target == DrinkTarget.he || (c.activePlayerName == c.player1Name);
      String name = isHe ? c.player1Name : c.player2Name;
      Color color = isHe ? c.player1Color : c.player2Color;
      DrinkTarget applyTarget = isHe ? DrinkTarget.he : DrinkTarget.she;
      String sipsText = c.currentTask!.sips > 0 ? ' (${c.currentTask!.sips})' : '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildDrinkButton('TOMA $name$sipsText', () {
                c.applySips(applyTarget, c.currentTask!.sips);
                c.nextTurnFromUI();
              }, color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDrinkButton('NO APLICA', () {
                c.nextTurnFromUI();
              }, Colors.white10),
            ),
          ],
        ),
      );
    }

    String sipsText = c.currentTask!.sips > 0 ? ' (${c.currentTask!.sips})' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDrinkButton('TOMA ${c.player1Name}$sipsText', () {
                  c.applySips(DrinkTarget.he, c.currentTask!.sips);
                  c.nextTurnFromUI();
                }, c.player1Color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrinkButton('TOMA ${c.player2Name}$sipsText', () {
                  c.applySips(DrinkTarget.she, c.currentTask!.sips);
                  c.nextTurnFromUI();
                }, c.player2Color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDrinkButton('TOMAN AMBOS$sipsText', () {
                  c.applySips(DrinkTarget.both, c.currentTask!.sips);
                  c.nextTurnFromUI();
                }, Colors.amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrinkButton('NADIE', () {
                  c.nextTurnFromUI();
                }, Colors.white10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkButton(String text, VoidCallback onPressed, Color color, {bool isLarge = false}) {
    return GameButton(
      text: text,
      onPressed: onPressed,
      style: color == Colors.white10 ? GameButtonStyle.secondary : GameButtonStyle.primary,
      customColor: color == Colors.white10 ? null : color,
      height: isLarge ? 70 : 60,
    );
  }

  String _getCategoryLabel(DrinkCategory category) {
    switch (category) {
      case DrinkCategory.question:
        return '🟦 PREGUNTA';
      case DrinkCategory.challenge:
        return '🟥 RETO';
      case DrinkCategory.punishment:
        return '🟩 CASTIGO';
      case DrinkCategory.decision:
        return '🟨 DECISIÓN';
    }
  }
}

class ShotGlassWidget extends StatefulWidget {
  final double fillPercent;
  final Color color;

  const ShotGlassWidget({
    super.key,
    required this.fillPercent,
    required this.color,
  });

  @override
  State<ShotGlassWidget> createState() => _ShotGlassWidgetState();
}

class _ShotGlassWidgetState extends State<ShotGlassWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<GlassBubble> _bubbles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // A slow, smooth animation that repeats for the bubble rise effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Generate persistent bubbles with varied speeds and starting heights
    _bubbles = List.generate(8, (index) {
      return GlassBubble(
        xRel: 0.35 + _random.nextDouble() * 0.3,
        yStart: _random.nextDouble(),
        speed: 0.4 + _random.nextDouble() * 0.4, // Reduced speed factor
        size: 1.0 + _random.nextDouble() * 2.0,
        wobbleSpeed: 1.5 + _random.nextDouble() * 2.0,
        wobbleScale: 0.015 + _random.nextDouble() * 0.015,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: GlassPainter(
            fillPercent: widget.fillPercent,
            color: widget.color,
            animationValue: _controller.value,
            bubbles: _bubbles,
          ),
        );
      },
    );
  }
}

class GlassBubble {
  final double xRel;       // Base horizontal percentage
  final double yStart;     // Starting vertical percentage (0 to 1)
  final double speed;      // Rising speed factor
  final double size;       // Bubble size in pixels
  final double wobbleSpeed;// Frequency of horizontal wobble
  final double wobbleScale;// Amplitude of horizontal wobble

  GlassBubble({
    required this.xRel,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.wobbleSpeed,
    required this.wobbleScale,
  });
}

class GlassPainter extends CustomPainter {
  final double fillPercent;
  final Color color;
  final double animationValue;
  final List<GlassBubble> bubbles;

  GlassPainter({
    required this.fillPercent,
    required this.color,
    required this.animationValue,
    required this.bubbles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final path = Path()
      ..moveTo(size.width * 0.15, 0)
      ..lineTo(size.width * 0.85, 0)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..close();

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(rect);
    canvas.drawPath(path, bgPaint);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 0),
        width: size.width * 0.7,
        height: 10,
      ),
      rimPaint,
    );

    if (fillPercent > 0) {
      final liquidHeight = size.height * fillPercent;
      final liquidTop = size.height - liquidHeight;

      final liquidPath = Path()
        ..moveTo(size.width * 0.15 + (size.width * 0.1 * (1 - fillPercent)), liquidTop)
        ..lineTo(size.width * 0.85 - (size.width * 0.1 * (1 - fillPercent)), liquidTop)
        ..lineTo(size.width * 0.75, size.height)
        ..lineTo(size.width * 0.25, size.height)
        ..close();

      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.9),
          ],
        ).createShader(liquidPath.getBounds());

      canvas.drawPath(liquidPath, liquidPaint);

      final surfacePaint = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      final surfaceWidth = size.width * (0.5 + (0.2 * fillPercent));

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, liquidTop),
          width: surfaceWidth,
          height: 10,
        ),
        surfacePaint,
      );

      // Draw slowly rising bubbles
      for (final bubble in bubbles) {
        // Calculate vertical position (rising from 1.0 to 0.0)
        double progress = (bubble.yStart - animationValue * bubble.speed) % 1.0;
        if (progress < 0) progress += 1.0;

        final bubbleY = liquidTop + progress * liquidHeight;

        // Subtle horizontal wiggle
        final wobble = sin(animationValue * bubble.wobbleSpeed * 2 * pi) * bubble.wobbleScale * size.width;
        final bubbleX = size.width * bubble.xRel + wobble;

        // Fade out when getting very close to the liquid surface
        final opacity = progress < 0.1 ? (progress / 0.1) * 0.35 : 0.35;

        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubble.size,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, outlinePaint);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(rect);
    canvas.drawPath(path, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant GlassPainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent ||
      oldDelegate.color != color ||
      oldDelegate.animationValue != animationValue;
}
