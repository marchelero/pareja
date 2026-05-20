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
  int _bestOf = 3; // 3, 5, or 7
  int _bombTimer = 5; // 5 or 7 seconds
  
  // Modifiers
  bool _optPanic = false;
  bool _optGold = false;
  bool _optWild = false;
  bool _optAccel = false;

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

              const SizedBox(height: 5),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'El primero en quedarse sin respuestas le da 1 punto al rival.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Middle Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Settings Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Column(
                                children: [
                                  // Best Of setting
                                  _buildSettingRow(
                                    icon: Icons.emoji_events,
                                    title: 'Formato:',
                                    child: DropdownButton<int>(
                                      value: _bestOf,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [3, 5, 7].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('Al mejor de $value'),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          _playSound();
                                          setState(() {
                                            _bestOf = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),

                                  // Timer setting
                                  _buildSettingRow(
                                    icon: Icons.hourglass_bottom,
                                    title: 'Tiempo:',
                                    child: DropdownButton<int>(
                                      value: _bombTimer,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [5, 7].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('$value Segundos'),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          _playSound();
                                          setState(() {
                                            _bombTimer = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),

                                  // Hot Mode Toggle
                                  _buildSettingRow(
                                    icon: Icons.whatshot,
                                    iconColor: Colors.pinkAccent,
                                    title: 'Modo Hot',
                                    child: Switch(
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Modifiers Title
                      const Text(
                        'REGLAS GLOBALES (Toda la partida)',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModifierBtn('Pánico', Icons.visibility_off, _optPanic, (val) => setState(() => _optPanic = val)),
                          const SizedBox(width: 20),
                          _buildModifierBtn('Acelerar', Icons.speed, _optAccel, (val) => setState(() => _optAccel = val)),
                        ],
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'EVENTOS (Turnos específicos)',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModifierBtn('Dorado', Icons.star, _optGold, (val) => setState(() => _optGold = val)),
                          const SizedBox(width: 20),
                          _buildModifierBtn('Comodín', Icons.style, _optWild, (val) => setState(() => _optWild = val)),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Explicación de Modificadores (Dinámica)
                      if (_optPanic || _optGold || _optWild || _optAccel)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_optPanic) _buildExplanationRow(Icons.visibility_off, 'Pánico: Oculta los números del reloj', Colors.white70),
                              if (_optGold) _buildExplanationRow(Icons.star, 'Dorado: Rondas al azar valen 2 puntos', Colors.amber),
                              if (_optWild) _buildExplanationRow(Icons.style, 'Comodín: 1 uso por partida para cambiar categoría', Colors.white70),
                              if (_optAccel) _buildExplanationRow(Icons.speed, 'Acelerar: El tiempo baja con cada toque', Colors.white70),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Selecciona modificadores arriba para ver qué hacen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Start Button (Fixed at bottom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      _playSound();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BombGameScreen(
                            isHotMode: _isHotMode,
                            bestOf: _bestOf,
                            timerSeconds: _bombTimer,
                            optPanic: _optPanic,
                            optGold: _optGold,
                            optWild: _optWild,
                            optAccel: _optAccel,
                          ),
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
                      '¡EMPEZAR PARTIDA!',
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

  Widget _buildSettingRow({required IconData icon, Color iconColor = Colors.white70, required String title, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

  Widget _buildModifierBtn(String label, IconData icon, bool isActive, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        _playSound();
        onChanged(!isActive);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 75,
        decoration: BoxDecoration(
          color: isActive ? Colors.deepOrange.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? Colors.deepOrange : Colors.white12,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.amber : Colors.white54, size: 28),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
