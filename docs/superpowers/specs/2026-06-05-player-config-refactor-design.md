# Player Config Refactor: Gender, Color & Friends Mode

## Goal

Replace the binary male/female (he/she, blue/pink) model with a configurable two-player system supporting any gender combination, customizable colors, and a "just friends" mode.

## Background

The app was originally designed for a male-female couple, with hardcoded assumptions:
- Player 1 = "he" = male = blue = ♂
- Player 2 = "she" = female = pink = ♀

This refactor makes each player independently configurable, supporting M-M, F-F, and M-F relationships, plus a friends mode that removes romantic UI elements.

## Data Model

### SettingsProvider fields

| Field | Type | Default (friends=false) | Default (friends=true) |
|---|---|---|---|
| `player1Name` | String | `"ÉL"` | `"J1"` |
| `player2Name` | String | `"ELLA"` | `"J2"` |
| `player1Gender` | PlayerGender (enum: male/female) | `male` | `male` |
| `player2Gender` | PlayerGender (enum: male/female) | `female` | `male` |
| `player1Color` | Color | auto-assigned | auto-assigned |
| `player2Color` | Color | auto-assigned | auto-assigned |
| `friendsMode` | bool | `false` | `true` |

### Auto-color assignment

Default colors are auto-assigned based on gender combination:

| Player 1 Gender | Player 2 Gender | Player 1 Color | Player 2 Color |
|---|---|---|---|
| male | female | `Colors.blueAccent` | `Colors.pinkAccent` |
| male | male | `Colors.blueAccent` | `Color(0xFF1565C0)` (darkBlue) |
| female | female | `Colors.pinkAccent` | `Color(0xFFC2185B)` (darkPink) |
| female | male | `Colors.pinkAccent` | `Colors.blueAccent` |

Manual color overrides persist independently — changing gender does not reset manually-chosen colors.

### LocalStorage keys

| Old Key | New Key | Type |
|---|---|---|
| `he_name` | `player1_name` | String |
| `she_name` | `player2_name` | String |
| — | `player1_gender` | String ("male"/"female") |
| — | `player2_gender` | String ("male"/"female") |
| — | `player1_color` | int (Color.value) |
| — | `player2_color` | int (Color.value) |
| — | `friends_mode` | bool |

### Migration

On first load after update, if `he_name` key exists:
- Migrate `he_name` → `player1_name`, `she_name` → `player2_name`
- Set genders: player1=male, player2=female
- Set colors: player1=blueAccent, player2=pinkAccent
- friends_mode = false
- Delete old keys

## Settings Screen

The existing Settings screen is reorganized:

### Player 1 Section
- **Name**: TextField (pre-filled with current name, like before)
- **Gender**: Toggle between ♂ Hombre / ♀ Mujer
- **Color**: Circle showing current color; tap opens a palette of 8 preset colors

### Player 2 Section
- Same layout as Player 1

### Mode Section
- Toggle between "❤️ Pareja" and "👫 Solo amigos"

### Existing Controls
- Sound and vibration toggles remain unchanged

## Home Screen

| Mode | Name Display | Subtitle |
|---|---|---|
| Pareja | `ÉL ♥ ELLA` (or custom names) | "COUPLE GAMES" |
| Solo Amigos | `J1 & J2` (or custom names) | "PARTY GAMES" |

- Heart icon is replaced by `&` in friends mode
- Gender icons (♂/♀) next to names reflect each player's actual gender
- The pulsing heart animation only plays in couple mode

## PlayerNamesSection (Game Menus)

Used in each game's start screen. Only name editing is available here.

- Default names depend on mode: "ÉL"/"ELLA" (couple) or "J1"/"J2" (friends)
- Gender icons dynamically show ♂ or ♀ per player's actual gender
- Color accents dynamically use each player's color
- Parameters changed: `heName`/`sheName` → `player1Name`/`player2Name`, added `player1Icon`/`player2Icon`/`player1Color`/`player2Color`

## CoinFlipWidget

| Old | New |
|---|---|
| `heName`, `sheName` | `player1Name`, `player2Name` |
| `isHeWinner` | `isPlayer1Winner` |
| `Colors.blueAccent` / `pinkAccent` | `player1Color` / `player2Color` |
| `Icons.male` / `Icons.female` | dynamic by player gender |

## GameResultScreen

- Player icons dynamically show ♂ or ♀ per gender
- Player colors dynamically from settings (remove `AppColors.playerHe`/`playerShe`)
- Player names from settings

## Controllers (All 10 Games)

Each controller follows this pattern:

```dart
// Old
String _heName = 'ÉL';
String _sheName = 'ELLA';
int _heScore = 0;
int _sheScore = 0;
bool _isHeTurn = true;
Color get heColor => Colors.blueAccent;
Color get sheColor => Colors.pinkAccent;

// New
String _player1Name = 'ÉL';
String _player2Name = 'ELLA';
int _player1Score = 0;
int _player2Score = 0;
bool _isPlayer1Turn = true;
Color _player1Color = Colors.blueAccent;
Color _player2Color = Colors.pinkAccent;
```

All controllers read from `SettingsProvider` on init.

## Game Screens

Every screen that uses `Colors.blueAccent`/`Colors.pinkAccent` changes to reference `_player1Color`/`_player2Color` from the controller.

This affects: Memory, Rapid Fire, Duel, Drinks, Bomb, Russian Roulette, Charades, Questions, Roulette, Never Have I Ever, and their start screens.

## Question Targeting

`Target.male` / `Target.female` in questions and `DrinkGender.male` / `DrinkGender.female` in drink tasks now map to whichever player has that gender, rather than being hardcoded to player1/player2.

Logic change in `QuestionsController`:
```dart
// Old
if (_isHeTurn) {
  available = qs.where((q) => q.target == Target.male || q.target == Target.any);
} else {
  available = qs.where((q) => q.target == Target.female || q.target == Target.any);
}

// New
final currentGender = _isPlayer1Turn ? _player1Gender : _player2Gender;
final targetForPlayer = currentGender == PlayerGender.male ? Target.male : Target.female;
available = qs.where((q) => q.target == targetForPlayer || q.target == Target.any);
```

Same pattern for `DrinksController` and `NeverHaveIEverController`.

## AppColors

Remove `playerHe`/`playerShe` constants. All color references are now dynamic per player.

## Affected Files (~35)

- `lib/core/constants/app_constants.dart` — defaults
- `lib/core/theme/app_colors.dart` — remove playerHe/playerShe
- `lib/core/storage/local_storage.dart` — new keys, migration
- `lib/core/models/player.dart` — no change needed
- `lib/providers/settings_provider.dart` — new fields
- `lib/screens/settings_screen.dart` — reorganized layout
- `lib/screens/home_screen.dart` — conditional heart, subtitle
- `lib/widgets/player_names_section.dart` — renamed parameters, dynamic icons/colors
- `lib/widgets/coin_flip_widget.dart` — renamed parameters, dynamic colors/icons
- `lib/widgets/game_result_screen.dart` — dynamic colors/icons
- All 10 controllers
- All game screens and start screens
- `lib/screens/questions/coin_flip_screen.dart`

## Out of Scope

- Friends mode does NOT remove game modes or question categories
- Friends mode does NOT filter questions by romantic content
- PlayerNamesSection in game menus remains name-only editing
- Game logic rules (scoring, turns, etc.) are unchanged — only renamed

## Migration Path

1. Add new fields to SettingsProvider + LocalStorage
2. Add migration from old keys
3. Update Settings screen UI
4. Update Home screen
5. Rename fields in PlayerNamesSection + CoinFlipWidget + GameResultScreen
6. Update all controllers (rename + add colors)
7. Update all game screens (use dynamic colors)
8. Update question/drink targeting logic
9. Remove AppColors.playerHe/playerShe
10. Full hot restart + smoke test all 10 games
