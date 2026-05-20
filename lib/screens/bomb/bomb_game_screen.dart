import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/models/bomb_category.dart';
import '../../core/models/drink_task.dart';
import '../../widgets/neon_background.dart';

class BombGameScreen extends StatefulWidget {
  final bool isHotMode;

  const BombGameScreen({super.key, required this.isHotMode});

  @override
  State<BombGameScreen> createState() => _BombGameScreenState();
}

class _BombGameScreenState extends State<BombGameScreen> with SingleTickerProviderStateMixin {
  List<BombCategory> _allCategories = [];
  List<BombCategory> _availableCategories = [];
  BombCategory? _currentCategory;
  
  List<DrinkTask> _punishments = [];

  bool _isLoading = true;
  bool _isPlaying = false;
  
  int _timeLeft = 5;
  Timer? _timer;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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
    // Load Categories
    final String categoriesStr = await rootBundle.loadString('assets/data/bomb_categories.json');
    final List<dynamic> catData = json.decode(categoriesStr);
    _allCategories = catData.map((json) => BombCategory.fromJson(json)).toList();
    
    // Filter categories
    _availableCategories = _allCategories.where((c) => widget.isHotMode || !c.isHot).toList();

    // Load Punishments (from drinks tasks or generic)
    try {
      final String drinksStr = await rootBundle.loadString('assets/data/drinks_tasks.json');
      final List<dynamic> drinksData = json.decode(drinksStr);
      final tasks = drinksData.map((json) => DrinkTask.fromJson(json)).toList();
      _punishments = tasks.where((t) => t.isHot == widget.isHotMode).toList();
    } catch (e) {
      _punishments = [];
    }

    _nextCategory();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _nextCategory() {
    if (_availableCategories.isEmpty) {
      _availableCategories = _allCategories.where((c) => widget.isHotMode || !c.isHot).toList();
    }
    
    final randomIndex = Random().nextInt(_availableCategories.length);
    setState(() {
      _currentCategory = _availableCategories[randomIndex];
      _availableCategories.removeAt(randomIndex);
      _timeLeft = 5;
      _isPlaying = false;
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
          _playSound('clic.mp3'); // Tic
          // Speed up pulse animation
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
      _timeLeft = 5;
      _pulseController.duration = const Duration(milliseconds: 500);
    });
  }

  void _explode() {
    _timer?.cancel();
    _playSound('game_over.mp3'); // Boom
    
    String punishmentText = "¡Pierdes! Te toca cumplir una fantasía de tu pareja.";
    if (_punishments.isNotEmpty) {
       final randomTask = _punishments[Random().nextInt(_punishments.length)];
       punishmentText = randomTask.text;
    }

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
                const Icon(Icons.explosion, size: 120, color: Colors.orange),
                const SizedBox(height: 30),
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
                const Text(
                  'Te quedaste en blanco...',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TU CASTIGO:',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        punishmentText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                      _nextCategory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('NUEVA CATEGORÍA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        _playSound('clic.mp3');
                        Navigator.pop(context);
                      },
                    ),
                    if (widget.isHotMode)
                      const Row(
                        children: [
                          Icon(Icons.whatshot, color: Colors.pink, size: 20),
                          SizedBox(width: 5),
                          Text('MODO HOT', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Category
              if (_currentCategory != null) ...[
                const Text(
                  'CATEGORÍA:',
                  style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _currentCategory!.text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Bomb Timer
              GestureDetector(
                onTap: _isPlaying ? _passTurn : _startGame,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: _isPlaying ? 1.05 : 1.0).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaying ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: _isPlaying ? Colors.redAccent : Colors.white24,
                        width: 4,
                      ),
                      boxShadow: _isPlaying ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ] : [],
                    ),
                    child: Center(
                      child: _isPlaying
                          ? Text(
                              '$_timeLeft',
                              style: TextStyle(
                                color: _timeLeft <= 2 ? Colors.redAccent : Colors.white,
                                fontSize: 100,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white),
                                Text('TOCAR PARA\nEMPEZAR', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Pass Button
              if (_isPlaying)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _passTurn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                      ),
                      child: const Text(
                        '¡PASAR!',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 140), // Placeholder to maintain space
            ],
          ),
        ),
      ),
    );
  }
}
