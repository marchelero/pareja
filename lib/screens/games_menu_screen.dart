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
import '../widgets/neon_background.dart';
import '../widgets/game_card.dart';
import '../widgets/route_transitions.dart';

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
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
