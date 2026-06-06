# A TIEMPO — Game Design

## Overview
Two-player reflex game where each player independently stops a running stopwatch as close to 10.00 seconds as possible. The closer player wins the point (double if exactly 10.00). First to N points wins the round; best-of-M rounds wins the match.

## Game Structure
- **Turn**: one player attempts to stop near 10.00. Timer runs freely past target; player taps DETENER to stop.
- **Comparison**: both players complete one turn → compare times → closest to 10.00 gets 1 point (2 if exact 10.00).
- **Round**: first to N points wins. [N configurable: 3/5/7]
- **Match**: best of M rounds wins the whole game. [M configurable: 3/5/7].

## Screens

### 1. Start Screen (`ATiempoStartScreen`)
- `PlayerNamesSection` (standard pattern)
- Glass card with:
  - **Puntos para ganar ronda**: chip selector [3 / 5 / 7], default 3
  - **Rondas al mejor de**: chip selector [3 / 5 / 7], default 3
- `GameButton` "EMPEZAR" → `CoinFlipScreen`

### 2. Game Screen (`ATiempoGameScreen`)
- Listener always present at root (stable widget tree, like Tiradedos fix).
- **States per "comparison" (both players try):**

| State | What user sees | Action |
|---|---|---|
| `waitingTurn` | Large `00.00`, "TURNO DE [JUGADOR]" | Botón **EMPEZAR** |
| `running` | Timer counting up in real-time | Botón **DETENER** |
| `turnDone` | Frozen time for current player | Brief pause, auto-advance |
| `bothDone` | Both times side-by-side + winner callout | Auto-advance after ~2.5s |
| `roundOver` | Banner "[NOMBRE] GANA LA RONDA" + scores | Auto-advance or tap to continue |
| `matchOver` | `GameResultScreen` with final result | "VOLVER A JUGAR" / "MENÚ PRINCIPAL" |

Display format: `00.00` (seconds.centiseconds, 10ms resolution).

Deterministic turn order: whoever wins the coin flip goes first, then alternates per comparison.

### 3. Result Screen
- Use existing `GameResultScreen` widget.

## Controller (`ATiempoController`)
Extends `ChangeNotifier`.

**Constructor params:**
- `AudioService`, `SettingsProvider`
- `pointsPerRound` (3/5/7, default 3)
- `matchRounds` (3/5/7, default 3)

**State fields (all private with public getters):**
- Player info (name, color, icon via `initGame()`)
- `_phase`: enum or strings (`GamePhase.waitingTurn`, `GamePhase.running`, etc.)
- `_currentTime`: double (0.0+)
- `_p1Time`, `_p2Time`: double? (frozen times)
- `_currentTurnPlayerIndex`: int (0 or 1)
- `_p1Points`, `_p2Points`: int (current round)
- `_p1Rounds`, `_p2Rounds`: int (match score)
- `_currentRound`: int
- `_comparisonCount`: int (turns within current comparison, 0/1/2)

**Key methods:**
- `initGame()`: load player info, reset all state.
- `setStartingPlayer(bool isP1)`: set who goes first.
- `startTimer()`: begin `Timer.periodic(10ms)`, set phase to `running`.
- `stopTimer()`: freeze `_currentTime`, set phase to `turnDone`, check if both done.
- `_evaluateComparison()`: compare `p1Time` vs `p2Time`, award point(s), check round win.
- `_startNewRound()`: reset points, increment round counter.
- `_checkMatchOver()`: if either player has `matchRounds ~/ 2 + 1` rounds, game over.
- `startNextTurn()`: start next player's turn (only called after both results shown).
- `resetGame()`: full reset.
- `dispose()`: cancel timer.

**Scoring:**
- `abs(time - 10.00)`: lower = better.
- Exact `10.00` → award 2 points.
- Tie → restart comparison (both try again).

## Files

### New files:
- `lib/controllers/atiempo_controller.dart`
- `lib/screens/atiempo/atiempo_start_screen.dart`
- `lib/screens/atiempo/atiempo_game_screen.dart`

### Modified files:
- `lib/core/theme/app_colors.dart` → add `modeATiempo = Color(0xFF00BCD4)`
- `lib/screens/games_menu_screen.dart` → add `GameCard` after Tiradedos

## Color
- Accent: `Color(0xFF00BCD4)` (cyan, unique in palette)
- Used for: VS text, timer display highlight, GameButton

## Edge Cases
- Both players get same time (tie) → repeat comparison.
- Timer never started by a player → treat as miss (time = 0 or high value).
- Timer stopped before 00.01 → possible, just a bad score.
- Navigation away mid-game → `dispose()` cancels timer.
