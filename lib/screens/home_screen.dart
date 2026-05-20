import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';
import 'games_menu_screen.dart';
import 'settings_screen.dart';
import '../widgets/neon_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _heName = '';
  String _sheName = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadNames();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    setState(() {
      _heName = he;
      _sheName = she;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Logo & Title
              _PulseLogo(controller: _pulseController),
              
              const SizedBox(height: 10),
              Text(
                'LOVEPLAY',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(color: Colors.pink, blurRadius: 25, offset: Offset(0, 5)),
                    Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              if (_heName.isNotEmpty && _sheName.isNotEmpty)
                Text(
                  'Hola, $_heName y $_sheName ❤️',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
              
              const Spacer(),

              // Buttons Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _GlassButton(
                      text: 'JUGAR',
                      icon: Icons.play_arrow_rounded,
                      isPrimary: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GamesMenuScreen()),
                        ).then((_) => _loadNames());
                      },
                    ),
                    const SizedBox(height: 20),
                    _GlassButton(
                      text: 'AJUSTES',
                      icon: Icons.settings_rounded,
                      isPrimary: false,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        ).then((_) => _loadNames());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseLogo extends StatelessWidget {
  final AnimationController controller;

  const _PulseLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
          // Gradient Heart
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.orange, Colors.pink, Colors.deepPurple],
            ).createShader(bounds),
            child: const Icon(Icons.favorite, size: 120, color: Colors.white),
          ),
          // Top Layer Icon (Small fire)
          Positioned(
            bottom: 25,
            right: 25,
            child: Icon(Icons.whatshot, size: 30, color: Colors.orange.shade300),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _GlassButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPrimary 
                ? [Colors.pink.withOpacity(0.5), Colors.orange.withOpacity(0.3)]
                : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
