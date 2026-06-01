# Modo Salvaje — Russian Roulette

## Overview
A second game mode for Russian Roulette where the drum respins after every shot, multiple bullets can be loaded, and each shot is an independent 50-50 (or configured probability).

## Start Screen Changes
- Toggle: "🔥 Modo Salvaje" below the "Mejor de" selector
- When ON, show a row of pill/chip buttons: `[2] [3] [4] [5]` for bullet count
- Default selection: 2
- Pass `wildMode` and `bulletCount` to controller

## Controller Changes
**New fields:**
- `_wildMode` (bool)
- `_bulletCount` (int, 2-5)
- `_bulletChambers` (Set<int>) — chamber indices that contain bullets

**`_startNewRound()`** — when wild mode, generate `_bulletCount` random indices instead of 1

**`pullTrigger()`** — wild mode:
- Empty: `_isClickResult = true`, `_isPlaying = false`, notify + audio → game screen handles respin
- Bullet: same bang flow (bang anim, round over, point to opponent)

**`startRespin()`** — new method:
- Re-generate `_bulletChambers` (randomize bullet positions)
- Switch turn: `_isHeTurn = !_isHeTurn`
- Set `_isSpinning = true`, `_isPlaying = false`
- `notifyListeners()`

**`endSpin()`** — unchanged (sets `_isPlaying = true` after spin completes)

## Game Screen Changes
**`_onControllerChange`**:
- Click result in wild mode: after 200ms delay, call `c.startRespin()` instead of 60° rotation

**Build method**:
- Hide history dots row when `c.wildMode` is true

## Flow
1. Round start → initial spin → user clicks "¡DISPARAR!"
2. Empty → show result (200ms) → full respin animation → turn switches → next player clicks
3. Bullet → bang anim → round over → dialog → next round

## Visual
- No history dots in wild mode
- Drum shows chambers; bullet chambers are indistinguishable from empty ones (same as normal mode)
