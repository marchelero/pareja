# Reporte Técnico Final
## Nuevo modo de juego #7 — Ruleta Rusa

> **Generado:** 2026-05-31 18:00
> **Proyecto:** LovePlay
> **Stack:** Flutter 3.5.2+ / Dart / Provider (ChangeNotifier)
> **Iteraciones realizadas:** 1
> **Veredicto final:** APROBADO CON OBSERVACIONES

---

## Objetivo confirmado

Nuevo modo de juego **#7 — Ruleta Rusa** para parejas, con mecánica de probabilidad incremental y animaciones visuales atractivas.

**Éxito cuando:**
- Pantalla de inicio con selección de rondas (Mejor de 3/5/7)
- Animación de giro del tambor (6 espacios, 1 bala) al iniciar cada ronda
- Animación de tensión al apretar el gatillo
- Animación de "clic" (vacío) con alivio, y animación de "disparo" (pérdida) con impacto
- Marcador visual de rondas ganadas (ÉL / ELLA)
- Pantalla de ganador de ronda y de la partida completa
- Integración en el menú de juegos como el 7° modo (grilla 3×3)
- Sin sonido (solo animaciones visuales)

**Fuera de alcance:**
- Modificar juegos existentes
- Cambiar el sistema de navegación global, tema visual, ni providers
- Agregar dependencias nuevas a pubspec.yaml
- Agregar penitencias o retos al perder ronda (solo puntos)

---

## Resumen del ciclo

| Iteración | Veredicto del Auditor | Fallas que motivaron reiteración |
|-----------|----------------------|----------------------------------|
| 1         | ⚠️ APROBADO CON OBS | Falla MEDIA: Color literal en controller (corregido in-situ). Observaciones BAJA documentadas. |

---

## Decisiones técnicas tomadas

### 1. Arquitectura del controlador

**Qué se decidió:**
Crear `RussianRouletteController` siguiendo el patrón `ChangeNotifier` exacto de `BombController`, con estados de animación expuestos como getters booleanos.

**Por qué se tomó esta decisión:**
Mantener consistencia arquitectónica con los 6 modos existentes. La game screen escucha cambios vía `addListener` y dispara animaciones según los flags booleanos del controller.

**Alternativas descartadas:**
- Controlador con estados enum (menos granular para animaciones)
- Animaciones manejadas enteramente desde la UI sin flags (mayor acoplamiento)

**Impacto en el código:**
El controller expone `isSpinning`, `isPullingTrigger`, `isClickResult`, `isBangResult` que la UI usa para gatillar `AnimationController`s específicos.

### 2. Estrategia de animaciones múltiples

**Qué se decidió:**
Usar `TickerProviderStateMixin` con 4 `AnimationController` independientes (spin, pulse, shake, bang), cada uno con su propia curva y duración.

**Por qué se tomó esta decisión:**
Cada animación necesita control de ciclo de vida independiente. El spin es one-shot, el pulse es repeat, el shake es forward corto, el bang es one-shot con elasticOut.

**Alternativas descartadas:**
- Un solo controller con Interval (complejidad innecesaria, difícil de sincronizar con los timers del controller)
- Implicit animations para todo (insuficiente para el shake y bang)

**Impacto en el código:**
4 controladores creados en `initState`, todos con `dispose()` en `dispose`. La lógica de activación vive en `_onControllerChange()`.

### 3. Representación visual del tambor

**Qué se decidió:**
6 cámaras posicionadas en hexágono (radio 70px) dentro de un círculo, con RotationTransition para el giro. El percutor (firing pin) está fuera del círculo rotatorio, en la parte superior.

**Por qué se tomó esta decisión:**
El tambor real gira mientras el percutor permanece fijo. Separar la animación del pin del tambor es visualmente correcto. Las 6 cámaras usan Positioned widgets calculados trigonométricamente.

**Alternativas descartadas:**
- CustomPainter (más rendimiento pero menos mantenible)
- Una sola imagen de revólver (menos interactivo, no muestra las cámaras)

**Impacto en el código:**
`_getChamberPositions()` calcula coordenadas polares. `_buildChambers()` pinta cada cámara con color según estado (gris=sin usar, verde=vacío, rojo=bala).

### 4. Mecánica de probabilidad incremental

**Qué se decidido:**
La bala se coloca aleatoriamente en una de 6 posiciones al inicio de la ronda. Cada gatillazo incrementa `_triggerPulls`. La posición actual es `(_triggerPulls - 1) % 6`. Si coincide con `_currentChamber`, el jugador pierde.

**Por qué se tomó esta decisión:**
Implementa fielmente la física de un revólver real: después de cada disparo vacío, el tambor avanza 1 posición. Sin re-giro entre turnos.

**Impacto en el código:**
Lógica lineal en `pullTrigger()`. No requiere random adicional entre turnos.

---

## Mapa de cambios

### Archivos nuevos

| Archivo | Propósito | Decisión clave asociada |
|---------|-----------|------------------------|
| `lib/controllers/russian_roulette_controller.dart` | Lógica del juego: turnos, probabilidad, puntuación | Arquitectura ChangeNotifier |
| `lib/screens/russian_roulette/russian_roulette_start_screen.dart` | Configuración previa a la partida (bestOf, nombres) | Patrón StartScreen existente |
| `lib/screens/russian_roulette/russian_roulette_game_screen.dart` | UI del juego con animaciones, tambor, gatillo | TickerProviderStateMixin + 4 controllers |

### Archivos modificados

| Archivo | Qué cambió | Por qué cambió |
|---------|-----------|---------------|
| `lib/core/theme/app_colors.dart` | + `modeRussianRoulette = Color(0xFFDC143C)` | Nuevo color para el 7° modo |
| `lib/screens/games_menu_screen.dart` | crossAxisCount 2→3, aspectRatio 1.3→1.0, +7ª tarjeta | Soportar 7 juegos en la grilla |

### Archivos eliminados

Ninguno.

---

## Cambios en archivos clave

### `lib/controllers/russian_roulette_controller.dart`

**Antes:** no existía
**Después:** Controller con 158 líneas, expone getters de estado, `pullTrigger()` con lógica de probabilidad incremental, callbacks `onRoundResult` y `onWinner`.
**Por qué es importante:** Es el cerebro del juego. Cualquier modificación a la mecánica (cantidad de balas, re-giro, penitencias) se hace aquí.

### `lib/screens/russian_roulette/russian_roulette_game_screen.dart`

**Antes:** no existía
**Después:** 521 líneas con 4 AnimationControllers, tambor hexagonal animado, botón de gatillo con sacudida, overlay de explosión, diálogos de resultado.
**Por qué es importante:** Contiene toda la experiencia visual. Las animaciones están acopladas a los flags del controller.

### `lib/screens/games_menu_screen.dart`

**Antes:** GridView 2×3 con 6 juegos
**Después:** GridView 3×3 con 7 juegos (layout 3+3+1). childAspectRatio ajustado a 1.0 para mejor espaciado.
**Por qué es importante:** Si se agrega un 8° juego, el layout 3×3 no funciona bien. Habrá que reconsiderar el diseño de la grilla.

---

## Criterios de éxito verificados

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| Pantalla de inicio con selección de rondas (3/5/7) | Cumplido | Dropdown en start screen con valores 3/5/7 |
| Animación de giro del tambor al iniciar cada ronda | Cumplido | RotationTransition 0→5 turns, 1.5s, bounceOut |
| Animación de tensión al apretar el gatillo | Cumplido | Pulse repeat(reverse) en el tambor + shake en el botón |
| Animación de "clic" con alivio | Cumplido | Overlay verde con check + fade out |
| Animación de "disparo" con impacto | Cumplido | Overlay rojo + escala elástica 1→3 + BOOM! |
| Marcador visual de rondas ganadas | Cumplido | ScoreBoard reutilizado de la app |
| Pantalla de ganador de ronda | Cumplido | RoundResultDialog (reutilizado) |
| Pantalla de ganador de partida | Cumplido | GameWinnerDialog (reutilizado) |
| Integración en el menú como 7° modo | Cumplido | Grilla 3×3 con nueva tarjeta + import |
| Sin sonido | Cumplido | Controller sin llamadas a audioService |

---

## Deuda técnica identificada

| # | Descripción | Severidad | Archivos afectados | Urgencia |
|---|-------------|-----------|-------------------|----------|
| 1 | `AudioService` como dependencia del controller sin ser usada (solo persiste para mantener el patrón de construcción consistente con otros juegos) | BAJA | `russian_roulette_controller.dart` | Sin urgencia. Si en el futuro se agregan sonidos, ya está la dependencia lista. |
| 2 | La animación de "clic" (vacío) reusa `_shakeController` para controlar su opacidad, resultando en una transición parcial (~300ms de fade) | BAJA | `russian_roulette_game_screen.dart` | Baja prioridad. Mejora cosmética para suavizar la transición de alivio. |

---

## Lo que el programador debe saber

- **Probabilidad incremental**: El juego NO re-gira el tambor entre turnos. La probabilidad aumenta de 1/6 hasta 6/6. Esto significa que en el 6° disparo la bala SALE SÍ O SÍ. Con 2 jugadores, el máximo de disparos por ronda es 6.
- **Sin sonido**: El controller no hace ninguna llamada a `audioService`. Si en el futuro se agregan sonidos, se deben conectar en el controller (playClick para gatillo, playGameOver para bang) o desde la game screen.
- **Dependencia AudioService**: Se mantiene en el constructor del controller por consistencia con los otros 6 modos, pero no se usa. Es segura ignorarla.
- **El color del modo es `0xFFDC143C` (Crimson)**: No conflictúa con `modeDrinks` (0xFF8B0000). Está centralizado en `AppColors.modeRussianRoulette`.
- **Layout del menú**: Con 7 juegos y `crossAxisCount: 3`, la grilla queda 3+3+1 (la última tarjeta centrada abajo). Si se agrega un 8° juego, habrá que cambiar el layout a 3+3+2 o reconsiderar el diseño.
- **Animaciones**: Los 4 AnimationControllers se disparan según flags booleanos del controller. No hay lógica de animación en el controller — la UI reacciona a los cambios de estado.

---

## Reportes de ejecución

| Iteración | Archivo de reporte |
|-----------|-------------------|
| 1         | `reports/2026-05-31_russian-roulette_iter1.md` |

Para ver los diffs completos y los commits atómicos de cada paso, consultar los reportes de ejecución individuales listados arriba.
