# Reporte Técnico Final
## Corrección de 4 bugs funcionales y 1 mejora visual en 13 juegos

> **Generado:** 2026-06-08 20:30
> **Proyecto:** LovePlay
> **Stack:** Flutter 3.5.2+ / Dart / Provider / shared_preferences / audioplayers
> **Iteraciones realizadas:** 2
> **Veredicto final:** APROBADO

---

## Objetivo confirmado

**Objetivo:** Corregir 4 bugs funcionales reportados (botones Preguntas, contador doble Chupitos, sonido duplicado Chupitos, brillo persistente Memoria) y estandarizar colores/iconos en menús de configuración (Premiado).

**Éxito cuando:**
- Botones Nada/Medio/Bien en modo Preguntas responden al toque
- Contador de turnos en Chupitos no suma doble cuando ambos toman
- Sonido drink en Chupitos no se duplica ni suena incorrectamente
- Brillo verde en Memoria no persiste tras acierto
- SectionTitle en pantalla de inicio de Premiado no usa colores hardcodeados
- `flutter analyze` reporta 0 issues

---

## Resumen del ciclo

| Iteración | Veredicto del Auditor | Fallas que motivaron reiteración |
|-----------|----------------------|----------------------------------|
| 1         | APROBADO             | —                                |
| 2         | APROBADO             | —                                |

---

## Decisiones técnicas tomadas

### B2 — Separación del avance de turno en game over

**Qué se decidió:**
Crear un método `_nextTask()` en `DrinksController` que asigna la siguiente tarea sin incrementar `_turnCount`, y usarlo desde `advanceAfterGameOver()`.

**Por qué se tomó esta decisión:**
El `_nextTurn()` siempre incrementa `_turnCount`. Cuando ambos toman y alguien se vacía, el flujo normal (`nextTurnFromUI()`) ya incrementó el contador. Al presionar SIGUIENTE en el diálogo, `advanceAfterGameOver()` llamaba a `_nextTurn()` de nuevo, duplicando el incremento. Separar la asignación de tarea del incremento de turno resuelve el problema limpio sin modificar la lógica normal.

**Alternativas descartadas:**
- No incrementar nunca en `advanceAfterGameOver()` simplemente: dejaría el turno sin avanzar si no hubo game over en el flujo normal.
- Pasar un flag booleano: más frágil, ensucia la interfaz.

**Impacto en el código:**
Solo afecta a `DrinksController` y los 7 puntos de llamada en `drinks_game_screen.dart`. No cambia la interfaz pública del controlador más que el retorno de `applySips`.

### B2 — `applySips` retorna `bool`

**Qué se decidió:**
Cambiar el tipo de retorno de `applySips` de `void` a `bool`, indicando si algún vaso se vació.

**Por qué se tomó esta decisión:**
La UI necesita saber si ocurrió un game over para decidir si llama `nextTurnFromUI()` o no. Sin este retorno, la UI no puede distinguir si un "ambos" vació un vaso (game over → diálogo → `advanceAfterGameOver`) o no (avance normal).

**Alternativas descartadas:**
- Que `applySips` internamente decida cuándo avanzar: rompe separación de responsabilidades.
- Usar un callback: innecesario para un solo bool de señal.

**Impacto en el código:**
7 puntos de llamada en `drinks_game_screen.dart` modificados para capturar el booleano y condicionar `nextTurnFromUI()`.

### B3 — Condición `<=` a `==` para sonido drink

**Qué se decidió:**
Cambiar la condición de disparo del sonido drink de `_heSipsLeft <= 0` a `_heSipsLeft == 0`.

**Por qué se tomó esta decisión:**
Con `<= 0`, si un vaso ya estaba vacío (por game over anterior) y se vuelve a llamar `applySips`, el sonido se dispara de nuevo aunque no haya bebido. Con `== 0`, solo suena en el momento exacto en que el vaso llega a cero.

**Impacto en el código:**
Una línea en `drinks_controller.dart`. Bajo riesgo.

### B3 — Resetear ambos vasos si ambos están vacíos en el diálogo

**Qué se decidió:**
En `_showContinueDialog`, después de resetear el vaso del perdedor, verificar si el otro jugador también está en 0 y resetearlo también.

**Por qué se tomó esta decisión:**
Si ambos se vacían simultáneamente (target "both"), el diálogo solo reseteaba al jugador que perdió. El otro quedaba en 0, y en la siguiente jugada `applySips` detectaba `_heSipsLeft == 0` o `_sheSipsLeft == 0` y disparaba sonido drink sin haber bebido.

**Impacto en el código:**
Tres líneas en `drinks_game_screen.dart`. Bajo riesgo.

### B4 — Listener de reverse en `_successFlashController`

**Qué se decidió:**
Agregar un `addStatusListener` en `_successFlashController` que ejecuta `.reverse()` cuando la animación alcanza `AnimationStatus.completed`.

**Por qué se tomó esta decisión:**
La animación se lanza con `forward(from: 0)` cada vez que hay un acierto. Si nunca se revierte, el tinte verde animado se queda permanentemente al 100%.

**Alternativas descartadas:**
- Usar `repeat(reverse: true)`: cambiaría la semántica del flash.
- Llamar `reverse()` desde `_onSuccess` después de un delay: inexacto y frágil.

**Impacto en el código:**
Tres líneas en `memory_game_screen.dart`. Bajo riesgo.

### B1 — `onTap` en lugar de `onTapUp` en GameButton

**Qué se decidió:**
Cambiar el callback de `GestureDetector` de `onTapUp` a `onTap`, manteniendo `onTapDown`/`onTapCancel` para el feedback visual de escala.

**Por qué se tomó esta decisión:**
`onTap` es más robusto que `onTapUp` en layouts que combinan `BackdropFilter` + `CustomScrollView`. En ciertos escenarios de scroll, `onTapUp` puede no dispararse si el widget se rebuild entre el down y el up. `onTap` maneja el ciclo completo internamente.

**Alternativas descartadas:**
- Eliminar BackdropFilter: posible pero cambia el diseño visual del componente.
- Usar InkWell + onTap: requeriría wrapper Material, cambiaría el layout.

**Impacto en el código:**
Un widget compartido (`game_button.dart`) usado en todos los modos de juego. Cambio mínimo, alto impacto positivo.

### M5 — Eliminar color hardcodeado en SectionTitle

**Qué se decidió:**
Eliminar el parámetro `color: AppColors.modePremiado` de ambos `SectionTitle` en la pantalla de inicio de Premiado, dejando que usen el default `AppColors.textSecondary`.

**Por qué se tomó esta decisión:**
La estandarización visual acordada indica que todos los SectionTitle en pantallas de inicio deben usar color blanco/neutro, no el color del modo. Premiado era el único que no cumplía.

**Impacto en el código:**
Dos líneas modificadas, un import eliminado. Muy bajo riesgo.

---

## Mapa de cambios

### Archivos modificados

| Archivo | Qué cambió | Por qué cambió |
|---------|-----------|---------------|
| `lib/controllers/drinks_controller.dart` | `applySips()`: `void` → `bool`; nuevo `_nextTask()` sin incrementar turno; `advanceAfterGameOver()` usa `_nextTask()`; condición sonido `<= 0` → `== 0` | B2 (contador doble) + B3 (sonido duplicado) |
| `lib/screens/drinks/drinks_game_screen.dart` | 7 callbacks condicionan `nextTurnFromUI()` al retorno de `applySips`; diálogo resetea ambos vasos si ambos vacíos | B2 + B3 |
| `lib/screens/memory/memory_game_screen.dart` | `addStatusListener` en `_successFlashController` con `reverse()` al completar | B4 (brillo persistente) |
| `lib/widgets/game_button.dart` | `onTapUp` → `onTap`; se mantienen `onTapDown`/`onTapCancel` para escala | B1 (botones no responden) |
| `lib/screens/premiado/premiado_start_screen.dart` | Se eliminó `color: AppColors.modePremiado` y el import de `app_colors.dart` | M5 (estandarizar colores) |

---

## Criterios de éxito verificados

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| Botones Nada/Medio/Bien responden al toque | Cumplido | `GameButton` usa `onTap` (más robusto), mantiene feedback visual |
| Contador de turnos no suma doble | Cumplido | `advanceAfterGameOver()` usa `_nextTask()` sin incrementar; UI condiciona `nextTurnFromUI()` |
| Sonido drink no se duplica | Cumplido | Condición cambiada a `== 0`; diálogo resetea ambos vasos |
| Brillo verde no persiste | Cumplido | Listener revierte animación al completar |
| SectionTitle sin colores hardcodeados | Cumplido | Color eliminado + import eliminado |
| `flutter analyze` → 0 issues | Cumplido | `No issues found!` |

---

## Deuda técnica identificada

Ninguna.

---

## Lo que el programador debe saber

- **`applySips` ahora retorna `bool`.** Cualquier nuevo código que llame este método debe capturar el retorno. Si retorna `true`, la UI no debe llamar `nextTurnFromUI()` (el avance se maneja desde el diálogo de game over).
- **GameButton cambió su comportamiento táctil.** El callback de `onTapUp` se movió a `onTap`. Si en el futuro se necesita la posición del tap (`onTapUp` provee `TapUpDetails`), habrá que reconsiderar esta decisión. Por ahora, ninguno de los usos necesita la posición.
- **Memoria: `_successFlashController` tiene un `addStatusListener`.** Si se reconstruye el controlador o se cambia su ciclo de vida, asegurarse de que este listener no se pierda o duplique.
- Los cambios de Iteración 1 (28 archivos) y los de Iteración 2 (5 archivos) están en el working directory sin commitear.

---

## Reportes de ejecución

| Iteración | Archivo de reporte |
|-----------|-------------------|
| 1         | `reports/2026-06-08_limpieza-documentacion-13-juegos_iter1.md` |
| 2         | `reports/2026-06-08_correccion-bugs-13-juegos_iter2.md` |

Para ver los diffs completos y los commits atómicos de cada paso,
consultar los reportes de ejecución individuales listados arriba.
