import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/models/bomb_category.dart';
import '../../core/storage/local_storage.dart';
import '../../widgets/neon_background.dart';

class BombGameScreen extends StatefulWidget {
  final bool isHotMode;
  final int bestOf;
  final int timerSeconds;
  
  // Modifiers
  final bool optPanic;
  final bool optGold;
  final bool optWild;
  final bool optAccel;

  const BombGameScreen({
    super.key,
    required this.isHotMode,
    required this.bestOf,
    required this.timerSeconds,
    required this.optPanic,
    required this.optGold,
    required this.optWild,
    required this.optAccel,
  });

  @override
  State<BombGameScreen> createState() => _BombGameScreenState();
}

class _BombGameScreenState extends State<BombGameScreen> with SingleTickerProviderStateMixin {
  List<BombCategory> _allCategories = [];
  List<BombCategory> _availableCategories = [];
  BombCategory? _currentCategory;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  
  late double _currentLimit; // Use double for acceleration logic
  late int _timeLeft;
  Timer? _timer;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  late String _heName;
  late String _sheName;
  int _scoreHe = 0;
  int _scoreShe = 0;
  late int _pointsToWin;
  bool _isHeTurn = true; 

  // Modifiers State
  bool _isGoldenRound = false;
  bool _heHasWildcard = false;
  bool _sheHasWildcard = false;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.timerSeconds.toDouble();
    _timeLeft = _currentLimit.ceil();
    _pointsToWin = (widget.bestOf / 2).floor() + 1;
    
    if (widget.optWild) {
      _heHasWildcard = true;
      _sheHasWildcard = true;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _initGame() async {
    _heName = await LocalStorage.getHeName();
    _sheName = await LocalStorage.getSheName();
    if (_heName.isEmpty) _heName = 'ÉL';
    if (_sheName.isEmpty) _sheName = 'ELLA';

    final String categoriesStr = await rootBundle.loadString('assets/data/bomb_categories.json');
    final List<dynamic> catData = json.decode(categoriesStr);
    _allCategories = catData.map((json) => BombCategory.fromJson(json)).toList();
    
    // Fix: Exact hot mode filter
    _availableCategories = _allCategories.where((c) => c.isHot == widget.isHotMode).toList();

    _nextRound();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _nextCategory({bool isWildcard = false}) {
    if (_availableCategories.isEmpty) {
      _availableCategories = _allCategories.where((c) => c.isHot == widget.isHotMode).toList();
    }
    
    final randomIndex = Random().nextInt(_availableCategories.length);
    setState(() {
      _currentCategory = _availableCategories[randomIndex];
      _availableCategories.removeAt(randomIndex);
      
      if (!isWildcard) {
        _currentLimit = widget.timerSeconds.toDouble();
        _timeLeft = _currentLimit.ceil();
      }
    });
  }

  void _nextRound() {
    _nextCategory();
    setState(() {
      _isPlaying = false;
      _isHeTurn = Random().nextBool(); 
      _pulseController.duration = const Duration(milliseconds: 500);

      if (widget.optGold) {
        // 35% chance of Golden Round so it appears more often
        _isGoldenRound = Random().nextDouble() < 0.35;
      }
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
    });
    _playSound('clic.mp3');
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _playSound('clic.mp3');
          _pulseController.duration = Duration(milliseconds: max(100, _timeLeft * 100));
        } else {
          _explode();
        }
      });
    });
  }

  void _passTurn() {
    if (!_isPlaying) return;
    _playSound('clic.mp3');
    setState(() {
      if (widget.optAccel) {
        _currentLimit = max(1.5, _currentLimit - 0.5); // Minimum 1.5 seconds
      }
      _timeLeft = _currentLimit.ceil();
      _isHeTurn = !_isHeTurn; 
      _pulseController.duration = Duration(milliseconds: max(100, _timeLeft * 100));
    });
  }

  void _useWildcard() {
    if (!_isPlaying) return;
    
    if (_isHeTurn && _heHasWildcard) {
      setState(() => _heHasWildcard = false);
    } else if (!_isHeTurn && _sheHasWildcard) {
      setState(() => _sheHasWildcard = false);
    } else {
      return; // No wildcard left
    }
    
    _playSound('clic.mp3');
    _nextCategory(isWildcard: true); // Does not reset timer!
  }

  void _explode() {
    _timer?.cancel();
    _playSound('game_over.mp3'); 
    
    bool heLost = _isHeTurn;
    int pointsEarned = _isGoldenRound ? 2 : 1;

    setState(() {
      if (heLost) {
        _scoreShe += pointsEarned;
      } else {
        _scoreHe += pointsEarned;
      }
    });

    bool isGameOver = _scoreHe >= _pointsToWin || _scoreShe >= _pointsToWin;

    if (isGameOver) {
      _showWinnerDialog(
        _scoreHe >= _pointsToWin ? _heName : _sheName, 
        _scoreHe >= _pointsToWin ? Colors.blueAccent : Colors.pinkAccent
      );
    } else {
      _showRoundResultDialog(heLost ? _heName : _sheName, pointsEarned);
    }
  }

  void _showRoundResultDialog(String loserName, int pointsEarned) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
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
                const Icon(Icons.local_fire_department, size: 100, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  '¡BOOM!',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡$loserName explotó!',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_isGoldenRound) ...[
                  const SizedBox(height: 10),
                  const Text('¡Ronda Dorada! +2 PUNTOS', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'MARCADOR',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(_heName, style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('$_scoreHe', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const Text('VS', style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                          Column(
                            children: [
                              Text(_sheName, style: const TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('$_scoreShe', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      _playSound('clic.mp3');
                      Navigator.pop(context);
                      _nextRound();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('SIGUIENTE RONDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [winnerColor.withOpacity(0.4), Colors.transparent],
                radius: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 120, color: winnerColor),
                const SizedBox(height: 30),
                const Text(
                  '¡TENEMOS GANADOR!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  winnerName.toUpperCase(),
                  style: TextStyle(
                    color: winnerColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: winnerColor, blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ha llegado a $_pointsToWin puntos.',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      _playSound('clic.mp3');
                      Navigator.pop(context); 
                      Navigator.pop(context); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winnerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('VOLVER AL MENÚ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Color activeColor = _isGoldenRound ? Colors.amber : (_isHeTurn ? Colors.blueAccent : Colors.pinkAccent);
    Color bgColor = _isGoldenRound ? Colors.amber.withOpacity(0.2) : (_isHeTurn ? Colors.blue.withOpacity(0.15) : Colors.pink.withOpacity(0.15));
    String activeName = _isHeTurn ? _heName : _sheName;
    
    bool activeHasWildcard = _isHeTurn ? _heHasWildcard : _sheHasWildcard;

    return Scaffold(
      backgroundColor: Colors.black, 
      body: GestureDetector(
        onTap: _isPlaying ? _passTurn : _startGame,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [bgColor, Colors.black],
              radius: 1.5,
              center: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header (Back button and Score)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                        onPressed: () {
                          _playSound('clic.mp3');
                          Navigator.pop(context);
                        },
                      ),
                      // Mini Scoreboard
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text('$_scoreHe', style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 20)),
                            ),
                            Text('$_scoreShe', style: const TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for centering
                    ],
                  ),
                ),

                // Active Global Rules Status Bar
                if (widget.optPanic || widget.optAccel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.optPanic) const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.visibility_off, color: Colors.white54, size: 16)),
                        if (widget.optAccel) const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.speed, color: Colors.white54, size: 16)),
                      ],
                    ),
                  ),

                const SizedBox(height: 5),

                // Turn Indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey<String>('$_isHeTurn-$_isGoldenRound'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: activeColor.withOpacity(0.5), width: _isGoldenRound ? 3 : 1),
                      boxShadow: _isGoldenRound ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10)] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isGoldenRound) const Icon(Icons.star, color: Colors.amber, size: 20),
                        if (_isGoldenRound) const SizedBox(width: 5),
                        Text(
                          'TURNO DE ${activeName.toUpperCase()}',
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Category Text
                if (_currentCategory != null) ...[
                  const Text(
                    'CATEGORÍA:',
                    style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _currentCategory!.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Bomb Timer Area
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: _isPlaying ? 1.05 : 1.0).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaying ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: _isPlaying ? activeColor : Colors.white24,
                        width: 4,
                      ),
                      boxShadow: _isPlaying ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ] : [],
                    ),
                    child: Center(
                      child: _isPlaying
                          ? (widget.optPanic
                              ? const Icon(Icons.local_fire_department, size: 120, color: Colors.redAccent)
                              : Text(
                                  '$_timeLeft',
                                  style: TextStyle(
                                    color: _timeLeft <= 2 ? Colors.redAccent : Colors.white,
                                    fontSize: 100,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, size: 60, color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  'TOCAR PARA\nEMPEZAR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const Spacer(),

                // Big instruction text or Wildcard at the bottom
                if (_isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: (widget.optWild && activeHasWildcard)
                        ? ElevatedButton.icon(
                            onPressed: _useWildcard,
                            icon: const Icon(Icons.style, color: Colors.amber, size: 28),
                            label: const Text(
                              'USAR COMODÍN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              side: const BorderSide(color: Colors.amber, width: 2),
                              elevation: 10,
                            ),
                          )
                        : TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.5, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app, color: Colors.white70),
                                      SizedBox(width: 10),
                                      Text(
                                        'TOCA LA PANTALLA PARA PASAR',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                else
                  const SizedBox(height: 90), // Maintain space
              ],
            ),
          ),
        ),
      ),
    );
  }
}
