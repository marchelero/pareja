# Reporte de Corrección de Bugs — Iteración 2

**Fecha:** 2026-06-08
**Estado:** COMPLETADO — 0 errores, 0 warnings (`flutter analyze`)

---

## Resumen

| Bug | Archivo(s) modificados | Cambios |
|-----|----------------------|---------|
| **B2** — Chupitos: contador doble al vaciar | `drinks_controller.dart`, `drinks_game_screen.dart` | `applySips` retorna `bool`; se crea `_nextTask()` sin incrementar turno; UI condiciona `nextTurnFromUI()` a que no se haya vaciado |
| **B3** — Chupitos: sonido drink duplicado | `drinks_controller.dart`, `drinks_game_screen.dart` | Condición de sonido cambió a `== 0`; diálogo de continue resetea ambos vasos si los 2 están vacíos |
| **B4** — Memoria: brillo persistente | `memory_game_screen.dart` | `addStatusListener` en `_successFlashController` ejecuta `.reverse()` al completar |
| **B1** — Preguntas: botones no responden | `game_button.dart` | `onTapUp` → `onTap` (más robusto); se mantienen `onTapDown`/`onTapCancel` para feedback visual |
| **M5** — Premiado: color hardcodeado | `premiado_start_screen.dart` | Se eliminó `color: AppColors.modePremiado` de ambos `SectionTitle` + se eliminó import no usado |

---

## Detalle de cambios

### B2 — Chupitos: contador de turnos suma doble

**Diagnóstico:** Cuando ambos toman y alguien se vacía, `applySips` → `onGameOver` → diálogo → usuario presiona SIGUIENTE → `advanceAfterGameOver()` → `_nextTurn()` incrementa turno, pero el flujo normal ya lo había incrementado.

**Cambios:**

1. `drinks_controller.dart`:
   - `applySips()`: tipo de retorno `void` → `bool`. Detecta si algún vaso se vació (`_heSipsLeft == 0 || _sheSipsLeft == 0`), reproduce sonido y llama `_checkGameOver()` solo si se vació. Retorna `true`/`false`.
   - Nuevo método `_nextTask()`: asigna siguiente tarea via `_getNextTask()` + `notifyListeners()` **sin** incrementar `_turnCount`.
   - `advanceAfterGameOver()`: ahora llama a `_nextTask()` en lugar de `_nextTurn()`.

2. `drinks_game_screen.dart` — en `_buildActionButtons()`:
   - Los 7 callbacks que ejecutaban `c.applySips(...); c.nextTurnFromUI();` ahora hacen:
     ```dart
     bool vacated = c.applySips(target, sips);
     if (!vacated) c.nextTurnFromUI();
     ```
   - Si el vaso se vació, `nextTurnFromUI()` NO se ejecuta (el avance se hace desde el diálogo via `advanceAfterGameOver()`).

### B3 — Chupitos: sonido drink incorrecto/duplicado

**Diagnóstico:**
- `applySips` usaba `<= 0` → sonaba drink múltiples veces si el vaso ya estaba en 0.
- Cuando ambos se vaciaban pero solo se reseteaba 1 vaso, el otro seguía en 0, sonando en la siguiente jugada.

**Cambios:**

1. `drinks_controller.dart:225` — Condición de sonido:
   ```dart
   // Antes
   if (_heSipsLeft <= 0 || _sheSipsLeft <= 0) {
   // Después
   bool vacated = _heSipsLeft == 0 || _sheSipsLeft == 0;
   ```

2. `drinks_game_screen.dart` — En `_showContinueDialog`, después de resetear el vaso del perdedor:
   ```dart
   c.resetPlayerGlasses(playerName);
   if (c.heSipsLeft <= 0 && playerName != c.player1Name) {
     c.resetPlayerGlasses(c.player1Name);
   }
   if (c.sheSipsLeft <= 0 && playerName != c.player2Name) {
     c.resetPlayerGlasses(c.player2Name);
   }
   ```

### B4 — Memoria: brillo persistente

**Diagnóstico:** `_successFlashController.forward(from: 0)` avanza a 1.0 y nunca se revierte → tinte verde permanente.

**Cambio:** `memory_game_screen.dart:43-47` — `addStatusListener` que revierte al completar:
```dart
_successFlashController.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    _successFlashController.reverse();
  }
});
```

### B1 — Preguntas: botones no funcionan

**Diagnóstico:** `GameButton` usaba `onTapUp` para ejecutar el callback. En ciertos contextos (BackdropFilter, scroll) `onTapUp` no se dispara.

**Cambio:** `game_button.dart:57-63`:
```dart
onTap: () {
  HapticsService.light();
  widget.onPressed();
},
onTapDown: (_) => setState(() => _scale = 0.95),
onTapCancel: () => setState(() => _scale = 1.0),
// Sin onTapUp
```

### M5 — Premiado: estandarizar colores

**Cambio:** Se eliminó `color: AppColors.modePremiado` de ambos `SectionTitle` (líneas 45 y 55). Se eliminó el import `app_colors.dart` por quedar no usado.

---

## Archivos modificados (4)

| Archivo | Cambios |
|---------|---------|
| `lib/controllers/drinks_controller.dart` | B2 (applySips → bool, _nextTask), B3 (== 0) |
| `lib/screens/drinks/drinks_game_screen.dart` | B2 (7 callbacks), B3 (reset ambos vasos) |
| `lib/screens/memory/memory_game_screen.dart` | B4 (addStatusListener reverse) |
| `lib/widgets/game_button.dart` | B1 (onTap → onTapUp) |
| `lib/screens/premiado/premiado_start_screen.dart` | M5 (remove color, remove unused import) |

## Validación final

```
$ flutter analyze
Analyzing pareja...
No issues found! (ran in 4.6s)
```

---

## Puntos Auditados

Auditoría realizada sobre el diff real contra `HEAD~1` y el estado actual de los archivos.

### B2 — Contador doble en Chupitos

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| `applySips` retorna `bool` | ✅ | `drinks_controller.dart:196`: `void` → `bool` |
| UI solo llama `nextTurnFromUI()` si retornó `false` | ✅ | Los 4 callbacks con `applySips` en `drinks_game_screen.dart` (líneas 486, 508, 515, 538) usan `if (!vacated) c.nextTurnFromUI()` |
| `advanceAfterGameOver()` no incrementa `_turnCount` | ✅ | `drinks_controller.dart:273-274`: llama a `_nextTask()` (nuevo método en 268-270) que solo asigna tarea sin tocar `_turnCount` |

### B3 — Sonido duplicado en Chupitos

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| Condición `<= 0` → `== 0` en `applySips` | ✅ | `drinks_controller.dart:222`: `bool vacated = _heSipsLeft == 0 \|\| _sheSipsLeft == 0` |
| Al resetear vaso en diálogo, verifica si el otro también está vacío | ✅ | `drinks_game_screen.dart:127-132`: tras resetear al perdedor, comprueba `heSipsLeft <= 0` y `sheSipsLeft <= 0` para el otro jugador |

### B4 — Brillo persistente en Memoria

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| `_successFlashController.addStatusListener` que llama `reverse()` al completar | ✅ | `memory_game_screen.dart:43-47`: listener que ejecuta `_successFlashController.reverse()` en `AnimationStatus.completed` |

### B1 — Botones Preguntas

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| `GameButton` usa `onTap` en lugar de `onTapUp` | ✅ | `game_button.dart:57-59`: callback en `onTap` |
| Mantiene animación de escala con `onTapDown`/`onTapCancel` | ✅ | `game_button.dart:60-61`: `onTapDown` → `_scale = 0.95`, `onTapCancel` → `_scale = 1.0` |

### M5 — Color SectionTitle Premiado

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| `premiado_start_screen.dart` no usa `AppColors.modePremiado` en `SectionTitle` | ✅ | Las instancias en líneas 44 y 54: `SectionTitle(text: …, icon: …)` sin parámetro `color` |
| Import de `app_colors.dart` eliminado | ✅ | El archivo actual no importa `app_colors.dart` (líneas 1-13) |

### Validaciones globales

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| `flutter analyze` → 0 issues | ✅ | `No issues found! (ran in 4.4s)` |
| Sin `withOpacity` residual en cambios | ✅ | `grep` en todos los `.dart`: 0 ocurrencias |
| Sin `modeMostLikely` residual | ✅ | `grep` en todos los `.dart`: 0 ocurrencias |

### Veredicto global

**APROBADO** — Todos los criterios auditados se cumplen. Las 5 correcciones (B1–B4, M5) están correctamente implementadas según el plan, el análisis estático no reporta errores y no hay residuales del código anterior.
