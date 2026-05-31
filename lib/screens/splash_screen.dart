import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

const Color _carbonBlack = Color(0xFF0D0D0D);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _startLoading();
  }

  Future<void> _startLoading() async {
    // 1. Cargar settings
    context.read<SettingsProvider>().load();

    // 2. Precargar Google Fonts para evitar flicker
    GoogleFonts.montserratTextTheme();
    GoogleFonts.dancingScriptTextTheme();
    GoogleFonts.playfairDisplayTextTheme();

    // 3. Esperar 3 segundos (animación de carga + descarga de fonts)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _carbonBlack,
      body: Stack(
        children: [
          // --- Logo centrado con fade-in ---
          Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: FractionallySizedBox(
                widthFactor: 0.55,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // --- Barra de carga blanca en la parte inferior ---
          Positioned(
            left: 40,
            right: 40,
            bottom: MediaQuery.of(context).padding.bottom + 60,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _loadingController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CARGANDO...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
