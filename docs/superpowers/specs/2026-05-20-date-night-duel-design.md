# Date Night Duel

## Concept
Couples adaptation of Buckshot Roulette. A love-pistol loaded with ❤️ (live) and 💨 (blank) shells. Players take turns shooting *themselves*. Survive a blank → earn a ⭐ Star Point + couple question. Get hit by ❤️ → lose a 💔 life. Win by KO or first to 3 ⭐.

## Mechanics
- **Tambor**: 6 shells per round, 3❤️ + 3💨, shuffled
- **Vidas**: 3💔 each
- **Acción por defecto**: Always shoot yourself
- **🎯 Redirigir** (1x per game): Redirect shot to partner. NOT usable when 1 shell left
- **💥 Cargar** (1x per game): Add an extra ❤️ to the cylinder
- **⭐ Punto Cita**: Earn by shooting yourself with 💨. Triggers a random couple question
- **Victoria**: KO opponent OR first to 3⭐

## Files
- `lib/screens/duel/duel_start_screen.dart`
- `lib/screens/duel/duel_game_screen.dart`
- `assets/data/duel_questions.json` (20 questions)
- `lib/screens/games_menu_screen.dart` (replace "Otros")

## Visual Theme
- Love pistol (gradient pink/purple container)
- Shells shown as pills: ❤️ (red) / 💨 (gray)
- Flame shot animation + screen shake on fire
- Glassmorphism UI consistent with rest of app
