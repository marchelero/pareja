import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/drinks_controller.dart';
import '../../core/models/drink_task.dart';
import '../../widgets/drink_game_over_dialog.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';

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
      _showGameOverDialog(playerName);
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

  void _showGameOverDialog(String playerName) {
    final c = widget.controller;
    bool isHe = playerName == c.heName;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return DrinkGameOverDialog(
          playerName: playerName,
          isHe: isHe,
          onVascoSecoSiguiente: () {
            Navigator.pop(context);
            c.resetPlayerGlasses(playerName);
            c.advanceAfterGameOver();
          },
        );
      },
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
        _buildGlass(c.heName, c.heSipsLeft, Colors.blue, c.sipsPerGlassParam),
        _buildGlass(c.sheName, c.sheSipsLeft, Colors.pink, c.sipsPerGlassParam),
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
          child: CustomPaint(
            painter: GlassPainter(fillPercent: fillPercent, color: color),
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
              child: _buildDrinkButton('TOMA ${c.heName}$sipsText', () {
                c.applySips(DrinkTarget.he, c.currentTask!.sips);
                c.nextTurnFromUI();
              }, Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDrinkButton('TOMA ${c.sheName}$sipsText', () {
                c.applySips(DrinkTarget.she, c.currentTask!.sips);
                c.nextTurnFromUI();
              }, Colors.pink),
            ),
          ],
        ),
      );
    }

    if (target == DrinkTarget.he || target == DrinkTarget.she ||
       ((target == DrinkTarget.random || target == DrinkTarget.loser) && c.activePlayerName != null)) {
      bool isHe = target == DrinkTarget.he || (c.activePlayerName == c.heName);
      String name = isHe ? c.heName : c.sheName;
      Color color = isHe ? Colors.blue : Colors.pink;
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
                child: _buildDrinkButton('TOMA ${c.heName}$sipsText', () {
                  c.applySips(DrinkTarget.he, c.currentTask!.sips);
                  c.nextTurnFromUI();
                }, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrinkButton('TOMA ${c.sheName}$sipsText', () {
                  c.applySips(DrinkTarget.she, c.currentTask!.sips);
                  c.nextTurnFromUI();
                }, Colors.pink),
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

class GlassPainter extends CustomPainter {
  final double fillPercent;
  final Color color;

  GlassPainter({required this.fillPercent, required this.color});

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

      final random = Random();
      for (int i = 0; i < 8; i++) {
        final bubbleX = size.width * (0.3 + random.nextDouble() * 0.4);
        final bubbleY = liquidTop + random.nextDouble() * liquidHeight;
        final bubbleSize = 1.0 + random.nextDouble() * 2.5;
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleSize,
          Paint()..color = Colors.white.withValues(alpha: 0.3),
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
      oldDelegate.fillPercent != fillPercent || oldDelegate.color != color;
}
