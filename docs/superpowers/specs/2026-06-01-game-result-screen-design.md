# Especificación: Pantalla de Resultados Unificada

**Fecha:** 2026-06-01
**Estado:** Aprobado por el usuario
**Modo:** Orquestador → Planner → Executor → Auditor

---

## Problema

Cada juego maneja el fin de partida de forma distinta:

| Juego | Cómo termina | Opciones de navegación |
|---|---|---|
| Preguntas | Pantalla completa `QuestionsResultScreen` | "VOLVER A JUGAR" (a StartScreen), "MENÚ PRINCIPAL" (a GamesMenuScreen) |
| Bomba | Dialog `GameWinnerDialog` | "VOLVER AL MENÚ" (pop 2x) — sin replay |
| Charadas | Dialog `GameWinnerDialog` | "VOLVER AL MENÚ" (pop 2x) — sin replay |
| Yo Nunca | Dialog `GameWinnerDialog` | "VOLVER AL MENÚ" (pop 2x) — sin replay |
| Ruleta Rusa | Dialog `GameWinnerDialog` | "VOLVER AL MENÚ" (pop 2x) — sin replay |
| Chupitos | Dialog `DrinkGameOverDialog` | Solo "VASO SECO, SIGUIENTE" — sin menu option |
| Ruleta | Perpetuo — no tiene fin | — |

No hay consistencia visual ni de navegación. El usuario debe poder decidir qué hacer al terminar: **repetir con misma configuración, ir al menú del juego, o ir al menú principal**.

## Solución

Crear un widget `GameResultScreen` compartido (enfoque híbrido) con:
- Layout base y navegación comunes
- Un slot `customStatsSection` para que cada juego muestre sus estadísticas específicas

## Arquitectura del componente

```
lib/
└── widgets/
    └── game_result_screen.dart    ← nuevo (compartido)
```

### Props

```dart
GameResultScreen({
  required String gameName,
  required Color gameColor,
  required String winnerName,
  required Color winnerColor,
  required String heName,
  required String sheName,
  required int scoreHe,
  required int scoreShe,
  bool isTie = false,
  Widget? customStatsSection,     // slot para stats específicas
  required VoidCallback onReplay,
  required VoidCallback onGameMenu,
  required VoidCallback onMainMenu,
})
```

## Diseño visual

```
┌──────────────────────────────────┐
│         NeonBackground           │
│  ┌────────────────────────────┐  │
│  │        🏆 (trofeo)         │  │
│  │    ¡VICTORIA! / ¡EMPATE!   │  │
│  │   NOMBRE GANADOR (neon)    │  │
│  │  ScoreBoard (ÉL vs ELLA)   │  │
│  ├────────────────────────────┤  │
│  │                            │  │
│  │  ◄ customStatsSection ►    │  │
│  │                            │  │
│  ├────────────────────────────┤  │
│  │  [🔄 VOLVER A JUGAR]      │  │
│  │  [🎮 MENÚ DEL JUEGO]      │  │
│  │  [🏠 MENÚ PRINCIPAL]      │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

- Animación staggered de entrada
- Trofeo y nombre del ganador en `winnerColor` (azul ÉL / rosa ELLA)
- Empate: icono 👏 + color púrpura
- Botones con gradientes neon, consistente con el theme actual

## Navegación

Cada juego detecta que terminó y hace:

```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => GameResultScreen(
      onReplay: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => XxxGameScreen(configuraciónActual)),
        );
      },
      onGameMenu: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const XxxStartScreen()),
        );
      },
      onMainMenu: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GamesMenuScreen()),
          (route) => false,
        );
      },
      ...
    ),
  ),
);
```

### Botones y destinos

| Botón | Destino | Implementación |
|---|---|---|
| VOLVER A JUGAR | Misma configuración, salta StartScreen | `pushReplacement` al `XxxGameScreen` |
| MENÚ DEL JUEGO | Pantalla de configuración del juego | `pushReplacement` al `XxxStartScreen` |
| MENÚ PRINCIPAL | Grid de todos los juegos | `pushAndRemoveUntil(GamesMenuScreen)` limpiando stack |

## Mapeo por juego

### Preguntas
- **customStatsSection:** `_QuestionsStats()` con Perfectas/Medias/Falladas + Muerte Súbita (migrar desde QuestionsResultScreen actual)
- **isTie:** sí (cuando scores iguales)
- **onReplay:** ir a `QuestionsGameScreen` con categorías seleccionadas (reutilizar `QuestionsConfig`)
- **onGameMenu:** ir a `QuestionsStartScreen`

### Bomba
- **customStatsSection:** rondas jugadas, rondas doradas
- **isTie:** sí
- **onReplay:** `BombGameScreen` usando `BombConfig` guardado
- **onGameMenu:** `BombStartScreen`
- _Reemplaza GameWinnerDialog + showGeneralDialog_

### Charadas
- **customStatsSection:** rondas jugadas, total aciertos por jugador
- **isTie:** sí
- **onReplay:** `CharadesGameScreen` con categorías actuales
- **onGameMenu:** `CharadesStartScreen`
- _Reemplaza GameWinnerDialog_

### Yo Nunca
- **customStatsSection:** rondas jugadas, veces que cada uno "nunca ha" / "sí ha"
- **isTie:** sí
- **onReplay:** `NeverHaveIEverGameScreen`
- **onGameMenu:** `NeverHaveIEverStartScreen`
- _Reemplaza GameWinnerDialog_

### Ruleta Rusa
- **customStatsSection:** rondas jugadas, rondas doradas
- **isTie:** sí
- **onReplay:** `RussianRouletteGameScreen` con wild mode config actual
- **onGameMenu:** `RussianRouletteStartScreen`
- _Reemplaza GameWinnerDialog_

### Chupitos
- **customStatsSection:** nivel alcanzado, total sorbos tomados por cada uno, quién perdió
- **isTie:** no (siempre pierde quien llega a 0 sorbos)
- **onReplay:** `DrinksGameScreen`
- **onGameMenu:** `DrinksStartScreen`
- _Reemplaza DrinkGameOverDialog_

### Ruleta
- **Sin cambios.** La ruleta es perpetua, no tiene condición de victoria.

## Archivos a modificar

| Archivo | Acción |
|---|---|
| `lib/widgets/game_result_screen.dart` | **CREAR** — nuevo componente compartido |
| `lib/screens/questions/questions_result_screen.dart` | **ELIMINAR** — reemplazado por GameResultScreen + _QuestionsStats |
| `lib/widgets/game_winner_dialog.dart` | **ELIMINAR** — ya no se usa |
| `lib/widgets/drink_game_over_dialog.dart` | **ELIMINAR** — ya no se usa |
| `lib/widgets/round_result_dialog.dart` | **MANTENER** — sigue usándose para rondas intermedias |
| `lib/screens/bomb/bomb_game_screen.dart` | Modificar `_showWinnerDialog` → pushReplacement a GameResultScreen |
| `lib/screens/charades/charades_game_screen.dart` | Modificar `_showWinnerDialog` → pushReplacement a GameResultScreen |
| `lib/screens/never_have_i_ever/never_have_i_ever_game_screen.dart` | Modificar `_showWinnerDialog` → pushReplacement a GameResultScreen |
| `lib/screens/russian_roulette/russian_roulette_game_screen.dart` | Modificar `_showWinnerDialog` → pushReplacement a GameResultScreen |
| `lib/screens/drinks/drinks_game_screen.dart` | Modificar fin de juego → pushReplacement a GameResultScreen |
| `lib/screens/questions/questions_game_screen.dart` | Modificar fin de juego → pushReplacement a GameResultScreen |

## No incluido (explícitamente fuera de alcance)

- La Ruleta sigue siendo perpetua, sin cambios.
- `RoundResultDialog` se mantiene para rondas intermedias.
- No se refactorizan controladores ni start screens.
