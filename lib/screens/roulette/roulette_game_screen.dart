import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/local_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/neon_background.dart';
import 'dart:ui';

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
  
  double _currentRotation = 0;
  String? _result;

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
      _options = data.cast<String>();
      _isLoading = false;
    });
  }

  void _toggleMode(bool value) {
    setState(() {
      _isLoading = true;
      _isDareMode = value;
      _result = null;
      _resultController.reset();
    });
    _initGame();
  }

  void _spin() {
    if (_isSpinning) return;
    _playSound();


    // If a result is already showing, it means the previous turn finished.
    // We automatically move to the next turn before spinning again.
    if (_result != null) {
      _nextTurn();
    }

    setState(() {
      _isSpinning = true;
      _result = null;
      _resultController.reset();
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
      setState(() {
        _isSpinning = false;
        _currentRotation = targetRotation % (2 * pi);
        
        final double sectionAngle = 2 * pi / _options.length;
        final double finalRotation = _animation.value;
        
        // Robust index calculation: find the section whose center is closest to the pointer (-pi/2)
        int foundIndex = 0;
        double minDiff = double.infinity;
        
        for (int i = 0; i < _options.length; i++) {
          // Section i center in original wheel coordinates is i * sectionAngle - pi/2
          // After rotation, its position is: (i * sectionAngle - pi/2 + finalRotation)
          double currentCenter = i * sectionAngle - pi / 2 + finalRotation;
          
          // Difference between current center and pointer (-pi/2)
          double diff = (currentCenter - (-pi / 2));
          // Normalize difference to [-pi, pi]
          double normalizedDiff = (diff + pi) % (2 * pi) - pi;
          
          if (normalizedDiff.abs() < minDiff) {
            minDiff = normalizedDiff.abs();
            foundIndex = i;
          }
        }
        
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
      _resultController.reset();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleHaptics);
    _controller.dispose();
    _resultController.dispose();
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
                        _buildRouletteWheel(constraints.maxHeight),
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

  Widget _buildRouletteWheel(double maxHeight) {
    // Adaptive size based on available height and width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double size = min(screenWidth * 0.9, maxHeight * 0.45);
    
    return GestureDetector(
      onTap: _spin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow and border
          Container(
            width: size + 10,
            height: size + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (_isDareMode ? Colors.red : Colors.blue).withOpacity(0.2),
                  blurRadius: 50,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // The Wheel
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _isSpinning ? _animation.value : _currentRotation,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: RoulettePainter(
                    options: _options,
                    isDareMode: _isDareMode,
                    heName: _heName,
                    sheName: _sheName,
                    isHeTurn: _isHeTurn,
                  ),
                ),
              );
            },
          ),
          // Center Pin
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
              gradient: RadialGradient(
                colors: [Colors.white, Colors.grey.shade300],
              ),
            ),
            child: Icon(
              _isDareMode ? Icons.whatshot : Icons.star,
              color: _isDareMode ? Colors.red : Colors.blue,
              size: 28,
            ),
          ),
          // Pointer (Top)
          Positioned(
            top: -15,
            child: Column(
              children: [
                Icon(
                  Icons.arrow_drop_down,
                  size: 70,
                  color: Colors.yellow.shade700,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ],
            ),
          ),
        ],
      ),
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
        '¡Toca la ruleta para girar!',
        style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class RoulettePainter extends CustomPainter {
  final List<String> options;
  final bool isDareMode;
  final String heName;
  final String sheName;
  final bool isHeTurn;

  RoulettePainter({
    required this.options,
    required this.isDareMode,
    required this.heName,
    required this.sheName,
    required this.isHeTurn,
  });

  String _formatText(String text) {
    final String targetName = isHeTurn ? sheName : heName;
    return text.replaceAll('{PAREJA}', targetName);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sectionAngle = 2 * pi / options.length;

    final List<Color> colors = isDareMode
        ? [Colors.red.shade700, Colors.red.shade400, Colors.orange.shade800, Colors.orange.shade500]
        : [Colors.blue.shade800, Colors.blue.shade500, Colors.cyan.shade700, Colors.cyan.shade400];

    for (int i = 0; i < options.length; i++) {
      // Draw Section
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.8)],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      // Center Section i such that Section 0 is centered at -pi/2
      final double startAngle = i * sectionAngle - pi / 2 - sectionAngle / 2;
      canvas.drawArc(rect, startAngle, sectionAngle, true, paint);

      // Draw lines between sections
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(startAngle), center.dy + radius * sin(startAngle)),
        linePaint,
      );

      // Draw Text (centered in section)
      _drawText(canvas, center, radius, startAngle + sectionAngle / 2, _formatText(options[i]));
    }

    // Outer Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Inner Border
    final innerBorderPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 4, innerBorderPaint);
  }

  void _drawText(Canvas canvas, Offset center, double radius, double angle, String text) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10, // Slightly smaller to fit more words
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    // maxWidth is limited to ensure it doesn't go outside the wheel
    textPainter.layout(maxWidth: radius * 0.6);
    
    // Position text starting at 30% of radius to leave room for center pin
    // and ending around 90% of radius
    textPainter.paint(
      canvas,
      Offset(radius * 0.3, -textPainter.height / 2),
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RoulettePainter oldDelegate) {
    return oldDelegate.isDareMode != isDareMode || 
           oldDelegate.options != options ||
           oldDelegate.isHeTurn != isHeTurn;
  }
}
