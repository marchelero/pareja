import 'dart:math';
import 'package:flutter/material.dart';
import '../../controllers/roulette_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptics_service.dart';
import '../../widgets/neon_background.dart';

class RouletteGameScreen extends StatefulWidget {
  final RouletteController controller;

  const RouletteGameScreen({
    super.key,
    required this.controller,
  });

  @override
  State<RouletteGameScreen> createState() => _RouletteGameScreenState();
}

class _RouletteGameScreenState extends State<RouletteGameScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late AnimationController _cardFlipController;
  late Animation<double> _cardFlipAnimation;

  double _currentRotation = 0;
  int _lastHapticSection = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerChange);

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _resultScale = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );

    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardFlipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardFlipController, curve: Curves.easeInOutBack),
    );

    _controller.addListener(_handleHaptics);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _handleHaptics() {
    if (!widget.controller.isSpinning) return;
    final double sectionAngle = 2 * pi / widget.controller.options.length;
    final double currentRotation = _animation.value;
    final int currentSection = (currentRotation / sectionAngle).floor();
    if (currentSection != _lastHapticSection) {
      HapticsService.light();
      _lastHapticSection = currentSection;
    }
  }

  void _spin() {
    final c = widget.controller;
    if (c.isSpinning) return;

    c.spin();

    _result = null;
    _selectedIndex = -1;
    _resultController.reset();
    _cardFlipController.reset();

    final random = Random();
    final double extraRotations = 6 + random.nextDouble() * 4;
    final double targetRotation = _currentRotation + extraRotations * 2 * pi;

    _animation = Tween<double>(
      begin: _currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.reset();
    _lastHapticSection = -1;
    _controller.forward().then((_) {
      if (!mounted) return;
      c.onSpinFinished(_animation.value);
      setState(() {
        _currentRotation = _animation.value % (2 * pi);
        _selectedIndex = c.selectedIndex;
        _result = c.result;
      });
      _cardFlipController.forward();
      _resultController.forward();
    });
  }

  String? _result;
  int _selectedIndex = -1;

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _controller.removeListener(_handleHaptics);
    _controller.dispose();
    _resultController.dispose();
    _cardFlipController.dispose();
    super.dispose();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildProgressBar(c),
                        _buildHeader(c),
                        const SizedBox(height: 10),
                        _buildTurnIndicator(c),
                        const Spacer(flex: 1),
                        _buildCardCarousel(c, constraints.maxHeight),
                        const Spacer(flex: 1),
                        _buildResultArea(c),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(RouletteController c) {
    double progress = (c.spinCount / c.maxSpinsForHot).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.deepOrangeAccent : Colors.orangeAccent,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            progress >= 1.0 ? '¡MODO HOT DESBLOQUEADO!' : 'Progreso para Modo Hot: ${c.spinCount}/${c.maxSpinsForHot}',
            style: TextStyle(
              color: progress >= 1.0 ? Colors.orangeAccent : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RouletteController c) {
    bool isHotUnlocked = c.spinCount >= c.maxSpinsForHot;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isHotUnlocked)
            Row(
              children: [
                const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 5),
                const Text('MODO HOT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: c.isDareMode,
                    onChanged: (val) => c.toggleMode(val),
                    activeThumbColor: Colors.redAccent,
                    activeTrackColor: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                c.isDareMode ? '🔥 ATREVIDA' : '✨ NORMAL',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(RouletteController c) {
    return Column(
      children: [
        const Text('Turno de', style: TextStyle(color: Colors.white60, fontSize: 14, letterSpacing: 3)),
        const SizedBox(height: 5),
        Text(
          c.currentPlayerName.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]),
        ),
      ],
    );
  }

  Widget _buildCardCarousel(RouletteController c, double maxHeight) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double ringSize = min(screenWidth * 0.92, maxHeight * 0.48);
    final double radius = ringSize * 0.36;
    final double cardWidth = ringSize * 0.22;
    final double cardHeight = cardWidth * 1.4;

    return GestureDetector(
      onTap: _spin,
      child: SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: (c.isDareMode ? Colors.red : Colors.blue).withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double rotation = c.isSpinning ? _animation.value : _currentRotation;
                return Stack(
                  children: List.generate(c.options.length, (i) {
                    final double a = i * 2 * pi / c.options.length + rotation;
                    final double x = radius * cos(a - pi / 2);
                    final double y = radius * sin(a - pi / 2);
                    return Positioned(
                      left: ringSize / 2 + x - cardWidth / 2,
                      top: ringSize / 2 + y - cardHeight / 2,
                      child: _buildCard(c, i, cardWidth, cardHeight),
                    );
                  }),
                );
              },
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: c.isDareMode
                      ? [Colors.red.shade500, Colors.orange.shade500]
                      : [Colors.blue.shade500, Colors.cyan.shade500],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (c.isDareMode ? Colors.red : Colors.blue).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 26),
            ),
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Icon(Icons.arrow_drop_down, size: 60, color: Colors.yellow.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(RouletteController c, int index, double cardWidth, double cardHeight) {
    final bool isSelected = index == _selectedIndex && _result != null;
    final Color cardPrimary = c.isDareMode ? AppColors.primary : AppColors.modeRoulette;
    final Color cardSecondary = c.isDareMode ? AppColors.primaryGradient : const Color(0xFF00BCD4);

    return AnimatedBuilder(
      animation: _cardFlipController,
      builder: (context, child) {
        final double flipValue = isSelected ? _cardFlipAnimation.value : 0;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flipValue * pi),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: flipValue > 0.5
                    ? [Colors.white, Colors.grey.shade100]
                    : [cardPrimary, cardSecondary],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white.withValues(alpha: 0.25),
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(color: Colors.yellow.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                    ]
                  : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(0, 2)),
                    ],
            ),
            child: flipValue > 0.5
                ? Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(pi),
                      child: Text('?', style: TextStyle(
                        color: c.isDareMode ? Colors.red.shade400 : Colors.blue.shade400,
                        fontSize: cardWidth * 0.45,
                        fontWeight: FontWeight.w900,
                      )),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          c.isDareMode ? Icons.whatshot : Icons.star,
                          size: cardWidth * 0.3,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 4),
                        Text('${index + 1}', style: TextStyle(
                          color: Colors.white,
                          fontSize: cardWidth * 0.35,
                          fontWeight: FontWeight.w900,
                        )),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResultArea(RouletteController c) {
    if (c.isSpinning) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('¡Girando...!', style: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
      );
    }

    if (_result != null) {
      return ScaleTransition(
        scale: _resultScale,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  BoxShadow(
                    color: (c.isDareMode ? Colors.red : Colors.blue).withValues(alpha: 0.4),
                    blurRadius: 25,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'RETO PARA ${c.currentPlayerName.toUpperCase()}:',
                    style: TextStyle(
                      color: c.isDareMode ? Colors.red.shade300 : Colors.blue.shade300,
                      fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.formatResultText(_result!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _result = null;
                    _selectedIndex = -1;
                  });
                  c.nextTurnFromUI();
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('SIGUIENTE TURNO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.isDareMode ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 120,
      alignment: Alignment.center,
      child: const Text('¡Toca el carrusel para girar!', style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.w500)),
    );
  }
}
