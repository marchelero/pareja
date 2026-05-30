import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/storage/local_storage.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'duel_game_screen.dart';

class DuelStartScreen extends StatefulWidget {
  const DuelStartScreen({super.key});

  @override
  State<DuelStartScreen> createState() => _DuelStartScreenState();
}

class _DuelStartScreenState extends State<DuelStartScreen> {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('DUELO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JUGADORES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.pinkAccent.withOpacity(0.8),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      PlayerNamesSection(
                        onChanged: (he, she) => setState(() {
                          _heName = he;
                          _sheName = she;
                        }),
                      ),
                      const SizedBox(height: 30),
                      _buildInfoBox(),
                      const SizedBox(height: 40),
                      _buildStartButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.pinkAccent, size: 20),
                  const SizedBox(width: 10),
                  Text('CÓMO JUGAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent.withOpacity(0.9), letterSpacing: 2, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('🔫', 'Siempre te disparas a ti mismo'),
              _infoRow('❤️', 'Bala de amor → pierdes una vida'),
              _infoRow('💨', 'Bala vacía → ganas ⭐ + pregunta'),
              _infoRow('🎯', 'Redirige el disparo a tu pareja (1 vez)'),
              _infoRow('💥', 'Agrega una ❤️ al tambor (1 vez)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () async {
            await LocalStorage.saveNames(_heName, _sheName);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DuelGameScreen(heName: _heName, sheName: _sheName),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.withOpacity(0.6), Colors.purple.withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Center(
              child: Text('¡EMPEZAR!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
            ),
          ),
        ),
      ),
    );
  }
}
