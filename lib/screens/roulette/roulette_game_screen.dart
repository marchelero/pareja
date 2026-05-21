import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/local_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/neon_background.dart';

class RouletteGameScreen extends StatefulWidget {
  final bool isDareMode;
  final bool startingPlayerIsHe;

  const RouletteGameScreen({
    super.key,
    required this.isDareMode,
    required this.startingPlayerIsHe,
  });

  @override
  State<RouletteGameScreen> createState() => _RouletteGameScreenState();
}

class _RouletteGameScreenState extends State<RouletteGameScreen> with TickerProviderStateMixin {
  List<String> _options = [];
  bool _isLoading = true;
  late String _heName;
  late String _sheName;
  late String _currentPlayerName;
  late bool _isHeTurn;
  late bool _isDareMode;
  int _spinCount = 0;
  final int _maxSpinsForHot = 8;

  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late AnimationController _cardFlipController;
  late Animation<double> _cardFlipAnimation;

  double _currentRotation = 0;
  String? _result;
  int _selectedIndex = -1;

  bool _isSpinning = false;
  int _lastHapticSection = -1;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clic.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  @override
  void initState() {
    super.initState();
    _isHeTurn = widget.startingPlayerIsHe;
    _isDareMode = widget.isDareMode;
    _initGame();

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

  void _handleHaptics() {
    if (!_isSpinning) return;

    final double sectionAngle = 2 * pi / _options.length;
    final double currentRotation = _animation.value;
    final int currentSection = (currentRotation / sectionAngle).floor();

    if (currentSection != _lastHapticSection) {
      LocalStorage.isVibrationEnabled().then((enabled) {
        if (enabled) HapticFeedback.lightImpact();
      });
      _lastHapticSection = currentSection;
    }
  }

  Future<void> _initGame() async {
    _heName = await LocalStorage.getHeName();
    _sheName = await LocalStorage.getSheName();
    if (_heName.isEmpty) _heName = 'ÉL';
    if (_sheName.isEmpty) _sheName = 'ELLA';

    _currentPlayerName = _isHeTurn ? _heName : _sheName;
    _spinCount = await LocalStorage.getRouletteSpinCount();

    final String fileName = _isDareMode ? 'roulette_dare.json' : 'roulette_normal.json';
    final String response = await rootBundle.loadString('assets/data/$fileName');
    final List<dynamic> data = json.decode(response);

    setState(() {
      _options = data.cast<String>().take(10).toList();
      _isLoading = false;
    });
  }

  void _toggleMode(bool value) {
    setState(() {
      _isLoading = true;
      _isDareMode = value;
      _result = null;
      _selectedIndex = -1;
      _resultController.reset();
      _cardFlipController.reset();
    });
    _initGame();
  }

  void _spin() {
    if (_isSpinning) return;
    _playSound();

    if (_result != null) {
      _nextTurn();
    }

    setState(() {
      _isSpinning = true;
      _result = null;
      _selectedIndex = -1;
      _resultController.reset();
      _cardFlipController.reset();
    });

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
    _controller.forward().then((_) {
      final double sectionAngle = 2 * pi / _options.length;
      final double finalRotation = _animation.value;

      int foundIndex = 0;
      double minDiff = double.infinity;

      for (int i = 0; i < _options.length; i++) {
        double currentCenter = i * sectionAngle - pi / 2 + finalRotation;
        double diff = (currentCenter - (-pi / 2));
        double normalizedDiff = (diff + pi) % (2 * pi) - pi;

        if (normalizedDiff.abs() < minDiff) {
          minDiff = normalizedDiff.abs();
          foundIndex = i;
        }
      }

      _cardFlipController.forward();

      setState(() {
        _isSpinning = false;
        _currentRotation = finalRotation % (2 * pi);
        _selectedIndex = foundIndex;
        _result = _options[foundIndex];
        _resultController.forward();
        _spinCount++;
        LocalStorage.saveRouletteSpinCount(_spinCount);

        LocalStorage.isVibrationEnabled().then((enabled) {
          if (enabled) HapticFeedback.vibrate();
        });
      });
    });
  }

  String _formatResultText(String text) {
    final String targetName = _isHeTurn ? _sheName : _heName;
    return text.replaceAll('{PAREJA}', targetName);
  }

  void _nextTurn() {
    setState(() {
      _isHeTurn = !_isHeTurn;
      _currentPlayerName = _isHeTurn ? _heName : _sheName;
      _result = null;
      _selectedIndex = -1;
      _resultController.reset();
      _cardFlipController.reset();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleHaptics);
    _controller.dispose();
    _resultController.dispose();
    _cardFlipController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                        _buildProgressBar(),
                        _buildHeader(),
                        const SizedBox(height: 10),
                        _buildTurnIndicator(),
                        const Spacer(flex: 1),
                        _buildCardCarousel(constraints.maxHeight),
                        const Spacer(flex: 1),
                        _buildResultArea(),
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

  Widget _buildProgressBar() {
    double progress = (_spinCount / _maxSpinsForHot).clamp(0.0, 1.0);
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
            progress >= 1.0 ? '¡MODO HOT DESBLOQUEADO!' : 'Progreso para Modo Hot: ${(_spinCount)}/$_maxSpinsForHot',
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

  Widget _buildHeader() {
    bool isHotUnlocked = _spinCount >= _maxSpinsForHot;
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
                const Text(
                  'MODO HOT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isDareMode,
                    onChanged: _toggleMode,
                    activeColor: Colors.redAccent,
                    activeTrackColor: Colors.redAccent.withOpacity(0.5),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _isDareMode ? '🔥 ATREVIDA' : '✨ NORMAL',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () {
              _playSound();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Column(
      children: [
        const Text(
          'Turno de',
          style: TextStyle(color: Colors.white60, fontSize: 14, letterSpacing: 3),
        ),
        const SizedBox(height: 5),
        Text(
          _currentPlayerName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
          ),
        ),
      ],
    );
  }

  Widget _buildCardCarousel(double maxHeight) {
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
            // Outer glow ring
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: (_isDareMode ? Colors.red : Colors.blue).withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            // Rotating cards
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double rotation = _isSpinning ? _animation.value : _currentRotation;
                return Stack(
                  children: List.generate(_options.length, (i) {
                    final double a = i * 2 * pi / _options.length + rotation;
                    final double x = radius * cos(a - pi / 2);
                    final double y = radius * sin(a - pi / 2);
                    return Positioned(
                      left: ringSize / 2 + x - cardWidth / 2,
                      top: ringSize / 2 + y - cardHeight / 2,
                      child: _buildCard(i, cardWidth, cardHeight),
                    );
                  }),
                );
              },
            ),
            // Center decorative heart
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isDareMode
                    ? [Colors.red.shade500, Colors.orange.shade500]
                    : [Colors.blue.shade500, Colors.cyan.shade500],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isDareMode ? Colors.red : Colors.blue).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 26),
            ),
            // Pointer
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Icon(
                Icons.arrow_drop_down,
                size: 60,
                color: Colors.yellow.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index, double cardWidth, double cardHeight) {
    final bool isSelected = index == _selectedIndex && _result != null;
    final ColorScheme colors = _isDareMode
        ? ColorScheme(
            brightness: Brightness.dark,
            primary: Colors.red.shade600,
            onPrimary: Colors.white,
            secondary: Colors.orange.shade600,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.red.shade800,
            onSurface: Colors.white,
          )
        : ColorScheme(
            brightness: Brightness.dark,
            primary: Colors.blue.shade600,
            onPrimary: Colors.white,
            secondary: Colors.cyan.shade600,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.blue.shade800,
            onSurface: Colors.white,
          );

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
                    : [colors.primary, colors.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white.withOpacity(0.25),
                width: isSelected ? 2.5 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: flipValue > 0.5
                ? Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(pi),
                      child: Text(
                        '?',
                        style: TextStyle(
                          color: _isDareMode ? Colors.red.shade400 : Colors.blue.shade400,
                          fontSize: cardWidth * 0.45,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDareMode ? Icons.whatshot : Icons.star,
                          size: cardWidth * 0.3,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: cardWidth * 0.35,
                            fontWeight: FontWeight.w900,
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

  Widget _buildResultArea() {
    if (_isSpinning) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          '¡Girando...!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.5,
          ),
        ),
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
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  BoxShadow(
                    color: (_isDareMode ? Colors.red : Colors.blue).withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'RETO PARA ${_currentPlayerName.toUpperCase()}:',
                    style: TextStyle(
                      color: _isDareMode ? Colors.red.shade300 : Colors.blue.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatResultText(_result!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
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
                  _playSound();
                  _nextTurn();
                },
                icon: const Icon(Icons.skip_next),
                label: const Text(
                  'SIGUIENTE TURNO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDareMode ? Colors.red : Colors.blue,
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
      child: const Text(
        '¡Toca el carrusel para girar!',
        style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}
