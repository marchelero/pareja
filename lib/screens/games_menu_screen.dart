import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/audio_service.dart';
import 'questions/questions_start_screen.dart';
import 'roulette/roulette_start_screen.dart';
import 'drinks/drinks_start_screen.dart';
import 'bomb/bomb_start_screen.dart';
import 'never_have_i_ever/never_have_i_ever_start_screen.dart';
import 'charades/charades_start_screen.dart';
import 'russian_roulette/russian_roulette_start_screen.dart';
import 'duel/duel_start_screen.dart';
import 'rapid_fire/rapid_fire_start_screen.dart';
import 'memory/memory_start_screen.dart';
import 'pairs/pairs_start_screen.dart';
import 'tiradedos/tiradedos_start_screen.dart';
import 'atiempo/atiempo_start_screen.dart';
import '../widgets/neon_background.dart';
import '../widgets/game_card.dart';
import '../widgets/route_transitions.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = context.read<AudioService>();

    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text(
                'TWO PLAYERS • JUEGOS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 2))
                  ],
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white54),
                onPressed: () {
                  audioService.playClick();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white54),
                  onPressed: () {
                    audioService.playClick();
                    Navigator.push(
                      context,
                      RouteTransitions.slideFromRight(const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  GameCard(
                    title: 'Preguntas',
                    icon: Icons.question_answer,
                    accentColor: AppColors.modeQuestions,
                    animationDelay: 0,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const QuestionsStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Ruleta',
                    icon: Icons.casino,
                    accentColor: AppColors.modeRoulette,
                    animationDelay: 100,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const RouletteStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Chupitos',
                    icon: Icons.local_bar,
                    accentColor: AppColors.modeDrinks,
                    animationDelay: 200,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const DrinksStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Bomba',
                    icon: Icons.timer,
                    accentColor: AppColors.modeBomb,
                    animationDelay: 300,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const BombStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Yo Nunca',
                    icon: Icons.psychology,
                    accentColor: AppColors.modeMostLikely,
                    animationDelay: 400,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const NeverHaveIEverStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Dígalo con Mímica',
                    icon: Icons.theater_comedy,
                    accentColor: AppColors.modeCharades,
                    animationDelay: 500,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const CharadesStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Ruleta Rusa',
                    icon: Icons.gps_fixed,
                    accentColor: AppColors.modeRussianRoulette,
                    animationDelay: 600,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const RussianRouletteStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Duelo',
                    icon: Icons.favorite,
                    accentColor: AppColors.modeDuel,
                    animationDelay: 700,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const DuelStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Alto al Fuego',
                    icon: Icons.bolt,
                    accentColor: AppColors.modeRapidFire,
                    animationDelay: 800,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const RapidFireStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Memoria',
                    icon: Icons.psychology,
                    accentColor: AppColors.modeMemory,
                    animationDelay: 900,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const MemoryStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Pares',
                    icon: Icons.crop_square,
                    accentColor: AppColors.modePairs,
                    animationDelay: 1000,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const PairsStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Tiradedos',
                    icon: Icons.touch_app,
                    accentColor: AppColors.modeTiradedos,
                    animationDelay: 1100,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const TiradedosStartScreen()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'A Tiempo',
                    icon: Icons.timer,
                    accentColor: AppColors.modeATiempo,
                    animationDelay: 1200,
                    onTap: () {
                      audioService.playClick();
                      Navigator.push(
                        context,
                        RouteTransitions.slideFromBottom(
                            const ATiempoStartScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
