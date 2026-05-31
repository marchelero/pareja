import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/neon_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_title.dart';
import '../widgets/neon_toggle.dart';
import '../widgets/neon_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _heController = TextEditingController();
  final TextEditingController _sheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    if (!settings.isLoaded) {
      settings.load().then((_) {
        if (mounted) {
          _heController.text = settings.heName;
          _sheController.text = settings.sheName;
        }
      });
    } else {
      _heController.text = settings.heName;
      _sheController.text = settings.sheName;
    }
  }

  @override
  void dispose() {
    _heController.dispose();
    _sheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text(
                  'CONFIGURACIÓN',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SectionTitle(
                      text: 'NOMBRES DE LA PAREJA',
                      icon: Icons.favorite,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _heController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nombre de ÉL',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.male,
                                  color: Colors.blueAccent),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryNeon),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _sheController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nombre de ELLA',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.female,
                                  color: Colors.pinkAccent),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primaryNeon),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          NeonButton(
                            text: 'GUARDAR NOMBRES',
                            onPressed: () async {
                              await settings.saveNames(
                                  _heController.text, _sheController.text);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Nombres guardados')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SectionTitle(
                      text: 'AJUSTES DE JUEGO',
                      icon: Icons.tune,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Column(
                        children: [
                          NeonToggle(
                            value: settings.soundEnabled,
                            onChanged: (_) => settings.toggleSound(),
                            icon: Icons.volume_up,
                            activeColor: AppColors.primaryNeon,
                          ),
                          const Divider(
                              color: Colors.white10, height: 24),
                          NeonToggle(
                            value: settings.vibrationEnabled,
                            onChanged: (_) => settings.toggleVibration(),
                            icon: Icons.vibration,
                            activeColor: AppColors.primaryNeon,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SectionTitle(
                      text: 'PROGRESO',
                      icon: Icons.analytics,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: const Text(
                            'Reiniciar Progreso de Ruleta',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Vuelve a empezar desde el giro 0',
                            style: TextStyle(color: Colors.white54),
                          ),
                          leading: const Icon(Icons.refresh,
                              color: Colors.redAccent),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.surfacePurple,
                                title: const Text(
                                  'Reiniciar progreso',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  '¿Estás seguro de que quieres reiniciar el progreso de la ruleta?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Reiniciar',
                                        style: TextStyle(
                                            color: AppColors.primaryNeon)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await settings.resetRouletteProgress();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Progreso de ruleta reiniciado')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'Pareja v1.0.0',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
