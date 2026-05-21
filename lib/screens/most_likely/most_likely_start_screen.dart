import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/storage/local_storage.dart';
import '../../widgets/neon_background.dart';
import 'most_likely_game_screen.dart';

class MostLikelyStartScreen extends StatefulWidget {
  const MostLikelyStartScreen({super.key});

  @override
  State<MostLikelyStartScreen> createState() => _MostLikelyStartScreenState();
}

class _MostLikelyStartScreenState extends State<MostLikelyStartScreen> {
  final TextEditingController _heController = TextEditingController();
  final TextEditingController _sheController = TextEditingController();
  int _bestOf = 5;
  bool _isHotMode = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    setState(() {
      _heController.text = he;
      _sheController.text = she;
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clic.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _heController.dispose();
    _sheController.dispose();
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
                        'LO MÁS PROBABLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '¿Quién es más probable que...? Adivinen y vean si coinciden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
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
                                  Row(
                                    children: [
                                      const Icon(Icons.male, color: Colors.blueAccent, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _heController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Nombre de ÉL',
                                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.3))),
                                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.female, color: Colors.pinkAccent, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _sheController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Nombre de ELLA',
                                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.3))),
                                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  _buildSettingRow(
                                    icon: Icons.emoji_events,
                                    title: 'Rondas:',
                                    child: DropdownButton<int>(
                                      value: _bestOf,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [3, 5, 7, 9].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('Al mejor de $value'),
                                        );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          _playSound();
                                          setState(() => _bestOf = newValue);
                                        }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  _buildSettingRow(
                                    icon: Icons.whatshot,
                                    iconColor: Colors.pinkAccent,
                                    title: 'Modo Hot',
                                    child: Switch(
                                      value: _isHotMode,
                                      onChanged: (value) {
                                        _playSound();
                                        setState(() => _isHotMode = value);
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      _playSound();
                      await LocalStorage.saveNames(_heController.text, _sheController.text);
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MostLikelyGameScreen(
                            bestOf: _bestOf,
                            isHotMode: _isHotMode,
                            heName: _heController.text,
                            sheName: _sheController.text,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isHotMode ? Colors.pink : Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: _isHotMode ? Colors.pink : Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      '¡EMPEZAR PARTIDA!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
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
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        child,
      ],
    );
  }
}
