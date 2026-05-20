import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/neon_background.dart';
import 'bomb_game_screen.dart';

class BombStartScreen extends StatefulWidget {
  const BombStartScreen({super.key});

  @override
  State<BombStartScreen> createState() => _BombStartScreenState();
}

class _BombStartScreenState extends State<BombStartScreen> {
  bool _isHotMode = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clic.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        _playSound();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'LA BOMBA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              const Spacer(),

              // Icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepOrange.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.timer,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Un juego de rapidez mental. La app te dará una categoría. Tienes 5 segundos para nombrar algo de esa categoría y pasar el turno.\n\n¡Si la bomba explota en tu turno, pierdes y cumples un castigo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Hot Mode Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.whatshot, color: Colors.pinkAccent),
                              SizedBox(width: 15),
                              Text(
                                'Modo Hot 🔥',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isHotMode,
                            onChanged: (value) {
                              _playSound();
                              setState(() {
                                _isHotMode = value;
                              });
                            },
                            activeColor: Colors.pinkAccent,
                            activeTrackColor: Colors.pinkAccent.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Start Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      _playSound();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BombGameScreen(isHotMode: _isHotMode),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isHotMode ? Colors.pink : Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: _isHotMode ? Colors.pink : Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '¡EMPEZAR A JUGAR!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
