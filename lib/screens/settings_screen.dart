import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/neon_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_title.dart';
import '../widgets/neon_toggle.dart';
import '../services/haptics_service.dart';
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

  void _confirmReset(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Resetear datos', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Borrar todos los datos? Los nombres, colores, ajustes y estadísticas volverán a sus valores de fábrica.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticsService.light();
              Navigator.pop(ctx);
            },
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              HapticsService.light();
              Navigator.pop(ctx);
              settings.resetAllData();
              _p1Controller.text = settings.player1Name;
              _p2Controller.text = settings.player2Name;
            },
            child: const Text('RESETEAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 16),

                    // ── JUGADOR 2 ──
                    SectionTitle(
                      text: 'JUGADOR 2',
                      icon: settings.player2Icon,
                      color: settings.player2Color,
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 16),

                    // ── MODO ──
                    SectionTitle(
                      text: 'MODO',
                      icon: settings.friendsMode ? Icons.people : Icons.favorite,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 6),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ModeButton(
                              icon: Icons.favorite,
                              label: 'PAREJA',
                              isSelected: !settings.friendsMode,
                              onTap: () => settings.setFriendsMode(false),
                            ),
                            const SizedBox(width: 16),
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
                    const SizedBox(height: 16),

                    // ── AJUSTES DE JUEGO ──
                    SectionTitle(
                      text: 'AJUSTES DE JUEGO',
                      icon: Icons.tune,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 6),
                    GlassCard(
                      child: Column(
                        children: [
                          NeonToggle(
                            value: settings.soundEnabled,
                            onChanged: (_) => settings.toggleSound(),
                            icon: Icons.volume_up,
                            activeColor: AppColors.primaryNeon,
                          ),
                          const Divider(color: Colors.white10, height: 12),
                          NeonToggle(
                            value: settings.vibrationEnabled,
                            onChanged: (_) => settings.toggleVibration(),
                            icon: Icons.vibration,
                            activeColor: AppColors.primaryNeon,
                          ),
                          const Divider(color: Colors.white10, height: 12),
                          _GuestModeRow(
                            value: settings.guestMode,
                            onChanged: (v) => settings.setGuestMode(v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── ESTADÍSTICAS ──
                    SectionTitle(
                      text: 'ESTADÍSTICAS',
                      icon: Icons.bar_chart,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 6),
                    _StatsSection(
                      gamesPlayed: settings.gamesPlayed,
                      favoriteGame: settings.favoriteGame,
                      estimatedPlayTime: settings.estimatedPlayTime,
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: 'RESETEAR DATOS',
                      icon: Icons.delete_forever,
                      variant: NeonButtonVariant.ghost,
                      onPressed: () => _confirmReset(settings),
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      text: 'GUARDAR CAMBIOS',
                      icon: Icons.save,
                      onPressed: () async {
                        await settings.setPlayer1Name(_p1Controller.text);
                        await settings.setPlayer2Name(_p2Controller.text);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Configuración guardada')),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
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
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final c = _presetColors[index];
                  final isSelected = c.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      HapticsService.light();
                      onColorChanged(c);
                    },
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
        onTap: () {
          HapticsService.light();
          onTap();
        },
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

class _GuestModeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GuestModeRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Icon(
          Icons.visibility_off,
          color: value ? AppColors.primaryNeon : Colors.white38,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Modo invitado (oculta nombres)',
          style: TextStyle(
            color: value ? Colors.white70 : Colors.white38,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticsService.light();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: value ? AppColors.primaryNeon.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: value ? AppColors.primaryNeon.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: value ? AppColors.primaryNeon.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int gamesPlayed;
  final String favoriteGame;
  final String estimatedPlayTime;

  const _StatsSection({
    required this.gamesPlayed,
    required this.favoriteGame,
    required this.estimatedPlayTime,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            _StatRow(icon: Icons.videogame_asset, label: 'Partidas totales', value: '$gamesPlayed'),
            const Divider(color: Colors.white10, height: 12),
            _StatRow(
              icon: Icons.emoji_events,
              label: 'Modo favorito',
              value: favoriteGame.isEmpty ? '—' : favoriteGame,
            ),
            const Divider(color: Colors.white10, height: 12),
            _StatRow(icon: Icons.access_time, label: 'Tiempo estimado', value: estimatedPlayTime),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
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
      onTap: () {
        HapticsService.light();
        onTap();
      },
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
