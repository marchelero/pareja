import 'dart:math';
import 'package:flutter/material.dart';
import 'questions_game_screen.dart';
import '../roulette/roulette_game_screen.dart';

class CoinFlipScreen extends StatefulWidget {
  final int maxRounds;
  final List<String> categories;
  final String heName;
  final String sheName;
  final bool isRoulette;
  final bool isDareMode;

  const CoinFlipScreen({
    super.key,
    required this.maxRounds,
    required this.categories,
    required this.heName,
    required this.sheName,
    this.isRoulette = false,
    this.isDareMode = false,
  });

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHeWinner = true;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _isHeWinner = Random().nextBool();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // 5 full rotations + final position
    double endValue = 5 * 2 * pi + (_isHeWinner ? 0 : pi);
    
    _animation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward().then((value) {
      setState(() {
        _showResult = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (widget.isRoulette) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RouletteGameScreen(
                  isDareMode: widget.isDareMode,
                  startingPlayerIsHe: _isHeWinner,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QuestionsGameScreen(
                  maxRounds: widget.maxRounds,
                  categories: widget.categories,
                  startingPlayerIsHe: _isHeWinner,
                ),
              ),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Quién empieza?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final angle = _animation.value;
                final isFront = (angle % (2 * pi)) < pi / 2 || (angle % (2 * pi)) > 3 * pi / 2;
                
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isFront ? _buildCoinFace(true) : _buildCoinFace(false),
                );
              },
            ),
            const SizedBox(height: 60),
            if (_showResult)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        Text(
                          '¡Empieza ${_isHeWinner ? (widget.heName.isEmpty ? 'ÉL' : widget.heName) : (widget.sheName.isEmpty ? 'ELLA' : widget.sheName)}!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _isHeWinner ? Colors.blue : Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Preparando preguntas...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinFace(bool isHe) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.amber,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.amber.shade700, width: 8),
        gradient: RadialGradient(
          colors: [Colors.amber.shade300, Colors.amber.shade700],
        ),
      ),
      child: Center(
        child: Icon(
          isHe ? Icons.male : Icons.female,
          size: 100,
          color: isHe ? Colors.blue.shade800 : Colors.pink.shade800,
        ),
      ),
    );
  }
}
