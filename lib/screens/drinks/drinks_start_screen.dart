import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/storage/local_storage.dart';
import 'drinks_game_screen.dart';
import '../../widgets/neon_background.dart';

class DrinksStartScreen extends StatefulWidget {
  const DrinksStartScreen({super.key});

  @override
  State<DrinksStartScreen> createState() => _DrinksStartScreenState();
}

class _DrinksStartScreenState extends State<DrinksStartScreen> {
  int _sipsPerGlass = 5;
  int _initialLevel = 1;
  int _levelingSpeed = 7; // Default to Medium (7 turns)
  bool _isHotMode = true;
  final TextEditingController _heController = TextEditingController();
  final TextEditingController _sheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    _heController.text = he;
    _sheController.text = she;
    setState(() {});
  }

  @override
  void dispose() {
    _heController.dispose();
    _sheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CONFIGURACIÓN CHUPITOS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
            _buildSectionTitle('JUGADORES'),
            _buildCard(
              child: Row(
                children: [
                  Expanded(child: _buildNameInput(_heController, Icons.male, Colors.blue)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.local_bar, color: Colors.amber, size: 30),
                  ),
                  Expanded(child: _buildNameInput(_sheController, Icons.female, Colors.pink)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('SORBOS POR VASO'),
            _buildCard(
              child: Column(
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cantidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('$_sipsPerGlass', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _sipsPerGlass.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      activeColor: Colors.pinkAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _sipsPerGlass = val.toInt()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('NIVEL INICIAL'),
            _buildCard(
              child: Column(
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Intensidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('Nivel $_initialLevel', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _initialLevel.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      activeColor: Colors.purpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _initialLevel = val.toInt()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('AJUSTES ADICIONALES'),
            _buildCard(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Velocidad de Subida de Nivel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                          _buildSpeedOption('Rápido', 4, Colors.pinkAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Medio', 7, Colors.purpleAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Lento', 10, Colors.blueAccent),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Sube de nivel cada $_levelingSpeed turnos',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Modo Hot', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Incluye retos picantes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isHotMode,
                    activeColor: Colors.pink,
                    onChanged: (val) => setState(() => _isHotMode = val),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 40),
              _buildStartButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.withOpacity(0.6), Colors.purple.withOpacity(0.4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: InkWell(
            onTap: () async {
              String heName = _heController.text.trim();
              String sheName = _sheController.text.trim();
              await LocalStorage.saveNames(
                heName.isEmpty ? 'ÉL' : heName,
                sheName.isEmpty ? 'ELLA' : sheName,
              );
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DrinksGameScreen(
                    sipsPerGlass: _sipsPerGlass,
                    initialLevel: _initialLevel,
                    levelingSpeed: _levelingSpeed,
                    isHotMode: _isHotMode,
                  ),
                ),
              );
            },
            child: const Center(
              child: Text(
                '¡EMPEZAR!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title, 
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 13, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 2,
          shadows: [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildNameInput(TextEditingController controller, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintText: icon == Icons.male ? 'ÉL' : 'ELLA',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.normal),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.3))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedOption(String label, int speed, Color color) {
    bool isSelected = _levelingSpeed == speed;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _levelingSpeed = speed),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? color : Colors.white10),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
