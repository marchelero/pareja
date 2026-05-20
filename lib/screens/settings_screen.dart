import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _heController = TextEditingController();
  final TextEditingController _sheController = TextEditingController();
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final he = await LocalStorage.getHeName();
    final she = await LocalStorage.getSheName();
    final sound = await LocalStorage.isSoundEnabled();
    final vibration = await LocalStorage.isVibrationEnabled();
    
    setState(() {
      _heController.text = he;
      _sheController.text = she;
      _soundEnabled = sound;
      _vibrationEnabled = vibration;
    });
  }

  Future<void> _saveNames() async {
    await LocalStorage.saveNames(_heController.text, _sheController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombres guardados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CONFIGURACIÓN', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.purple.shade900.withOpacity(0.2)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle('NOMBRES DE LA PAREJA'),
            _buildCard([
              _buildTextField(
                controller: _heController,
                label: 'Nombre de Él',
                icon: Icons.male,
                color: Colors.blue,
              ),
              const Divider(color: Colors.white10),
              _buildTextField(
                controller: _sheController,
                label: 'Nombre de Ella',
                icon: Icons.female,
                color: Colors.pink,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveNames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('GUARDAR NOMBRES'),
              ),
            ]),
            const SizedBox(height: 30),
            _buildSectionTitle('AJUSTES DE JUEGO'),
            _buildCard([
              SwitchListTile(
                title: const Text('Sonido', style: TextStyle(color: Colors.white)),
                secondary: const Icon(Icons.volume_up, color: Colors.blueAccent),
                value: _soundEnabled,
                onChanged: (val) async {
                  await LocalStorage.setSoundEnabled(val);
                  setState(() => _soundEnabled = val);
                },
                activeColor: Colors.pink,
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                title: const Text('Vibración', style: TextStyle(color: Colors.white)),
                secondary: const Icon(Icons.vibration, color: Colors.orangeAccent),
                value: _vibrationEnabled,
                onChanged: (val) async {
                  await LocalStorage.setVibrationEnabled(val);
                  setState(() => _vibrationEnabled = val);
                },
                activeColor: Colors.pink,
              ),
            ]),
            const SizedBox(height: 30),
            _buildSectionTitle('PROGRESO'),
            _buildCard([
              ListTile(
                title: const Text('Reiniciar Progreso de Ruleta', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Vuelve a empezar desde el giro 0', style: TextStyle(color: Colors.white54)),
                leading: const Icon(Icons.refresh, color: Colors.redAccent),
                onTap: () async {
                  await LocalStorage.resetRouletteProgress();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progreso de ruleta reiniciado')),
                  );
                },
              ),
            ]),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Pareja v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.pink.shade300,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: color),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}
