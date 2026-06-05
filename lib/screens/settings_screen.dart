import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/neon_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_title.dart';
import '../widgets/neon_toggle.dart';
import '../widgets/neon_button.dart';

const List<Color> _presetColors = [
  Color(0xFF448AFF), // blueAccent
  Color(0xFFFF4081), // pinkAccent
  Color(0xFF69F0AE), // greenAccent
  Color(0xFFFF6D00), // deepOrangeAccent
  Color(0xFFE040FB), // purpleAccent
  Color(0xFF64FFDA), // tealAccent
  Color(0xFFFF5252), // redAccent
  Color(0xFFFFD740), // amberAccent
  Color(0xFF536DFE), // indigoAccent
  Color(0xFF00E676), // green
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _p1Controller = TextEditingController();
  final TextEditingController _p2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    if (!settings.isLoaded) {
      settings.load().then((_) {
        if (mounted) {
          _p1Controller.text = settings.player1Name;
          _p2Controller.text = settings.player2Name;
        }
      });
    } else {
      _p1Controller.text = settings.player1Name;
      _p2Controller.text = settings.player2Name;
    }
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
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
                    // ── JUGADOR 1 ──
                    SectionTitle(
                      text: 'JUGADOR 1',
                      icon: settings.player1Icon,
                      color: settings.player1Color,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: _PlayerConfigSection(
                        nameController: _p1Controller,
                        gender: settings.player1Gender,
                        color: settings.player1Color,
                        nameHint: 'J1',
                        onGenderChanged: (g) => settings.setPlayer1Gender(g),
                        onColorChanged: (c) => settings.setPlayer1Color(c),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── JUGADOR 2 ──
                    SectionTitle(
                      text: 'JUGADOR 2',
                      icon: settings.player2Icon,
                      color: settings.player2Color,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: _PlayerConfigSection(
                        nameController: _p2Controller,
                        gender: settings.player2Gender,
                        color: settings.player2Color,
                        nameHint: 'J2',
                        onGenderChanged: (g) => settings.setPlayer2Gender(g),
                        onColorChanged: (c) => settings.setPlayer2Color(c),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── MODO ──
                    SectionTitle(
                      text: 'MODO',
                      icon: settings.friendsMode ? Icons.people : Icons.favorite,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ModeButton(
                              icon: Icons.favorite,
                              label: 'PAREJA',
                              isSelected: !settings.friendsMode,
                              onTap: () => settings.setFriendsMode(false),
                            ),
                            const SizedBox(width: 24),
                            _ModeButton(
                              icon: Icons.people,
                              label: 'AMIGOS',
                              isSelected: settings.friendsMode,
                              onTap: () => settings.setFriendsMode(true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save names button ──
                    NeonButton(
                      text: 'GUARDAR NOMBRES',
                      onPressed: () async {
                        await settings.setPlayer1Name(_p1Controller.text);
                        await settings.setPlayer2Name(_p2Controller.text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nombres guardados')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 30),

                    // ── AJUSTES DE JUEGO ──
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
                          const Divider(color: Colors.white10, height: 24),
                          NeonToggle(
                            value: settings.vibrationEnabled,
                            onChanged: (_) => settings.toggleVibration(),
                            icon: Icons.vibration,
                            activeColor: AppColors.primaryNeon,
                          ),
                        ],
                      ),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerConfigSection extends StatelessWidget {
  final TextEditingController nameController;
  final PlayerGender gender;
  final Color color;
  final String nameHint;
  final ValueChanged<PlayerGender> onGenderChanged;
  final ValueChanged<Color> onColorChanged;

  const _PlayerConfigSection({
    required this.nameController,
    required this.gender,
    required this.color,
    required this.nameHint,
    required this.onGenderChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = gender == PlayerGender.male;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: Icon(isMale ? Icons.male : Icons.female, color: color),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: const BorderSide(color: AppColors.primaryNeon),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _GenderChip(
              icon: Icons.male,
              label: 'HOMBRE',
              isSelected: isMale,
              color: color,
              onTap: () => onGenderChanged(PlayerGender.male),
            ),
            const SizedBox(width: 12),
            _GenderChip(
              icon: Icons.female,
              label: 'MUJER',
              isSelected: !isMale,
              color: color,
              onTap: () => onGenderChanged(PlayerGender.female),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Color',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const Spacer(),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: _presetColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final c = _presetColors[index];
                  final isSelected = c.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => onColorChanged(c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GenderChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white38, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNeon.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryNeon : Colors.white38, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryNeon : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
