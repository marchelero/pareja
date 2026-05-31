# Reporte Técnico Final
## Rediseño Visual — TWO PLAYERS (Pareja)

> **Generado:** 2026-05-30
> **Proyecto:** TWO PLAYERS (pareja)
> **Stack:** Flutter 3.5.2+ / Dart / Provider
> **Iteraciones realizadas:** 1
> **Veredicto final:** ✅ APROBADO

---

## Objetivo confirmado

Rediseñar la interfaz visual completa de la app TWO PLAYERS, refinando el estilo
neón romántico actual hacia una versión más premium, pulida y cinematográfica,
sin modificar lógica de juego, datos ni funcionalidad existente.

**Dirección estética:** Neón Romántico Premium (Opción A)

**Criterios de éxito:**
- HomeScreen con staggered animations y badge de pareja con nombres reales
- Botones con micro-interacciones (shimmer, glow, escala)
- GamesMenuScreen con cards glassmorphism y staggered entry
- SettingsScreen con glassmorphism consistente y toggles personalizados
- NeonBackground con sistema de partículas animadas
- Transiciones personalizadas entre pantallas
- Nuevos widgets compartidos reutilizables
- `flutter analyze` sin errores ni warnings
- No rotura de funcionalidad existente

---

## Resumen del ciclo

| Iteración | Veredicto del Auditor | Fallas que motivaron reiteración |
|-----------|----------------------|----------------------------------|
| 1         | ✅ APROBADO           | —                                |

---

## Decisiones técnicas tomadas

### 1. Nueva paleta de color

**Qué se decidió:**
Refinar los colores base con tonos más intensos y agresivos: rosa neón
`#FF2D78`, naranja `#FF6B35`, y un nuevo púrpura terciario `#B44AFF`.

**Por qué se tomó esta decisión:**
Los colores anteriores (`#FF416C`, `#FFAB40`) eran demasiado suaves para
transmitir la sensación "premium" buscada. Los nuevos tonos tienen mayor
saturación y contraste, funcionando mejor sobre fondos oscuros.

**Alternativas descartadas:**
- Mantener la paleta exacta — no daba suficiente diferenciación visual
- Paleta con azules y fríos — rompía la identidad romántica establecida

**Impacto en el código:**
- Renombrado `modeDuel` → `modeCharades` en `AppColors`
- Nuevos colores agregados sin eliminar los anteriores

### 2. Widget NeonButton en vez de _GlassButton

**Qué se decidió:**
Crear un `NeonButton` reutilizable con 3 variantes (primary, secondary, ghost)
en lugar del `_GlassButton` privado que solo existía en HomeScreen.

**Por qué se tomó esta decisión:**
El botón primario con shimmer + glow se necesitaba también en SettingsScreen.
Centralizar la lógica evita duplicación y permite consistencia visual.

**Alternativas descartadas:**
- Modificar el `GameButton` existente — está diseñado con otra semántica
- Mantener `_GlassButton` duplicado — viola DRY

**Impacto en el código:**
Widget nuevo en `lib/widgets/neon_button.dart` (208 líneas), usado en
HomeScreen y SettingsScreen.

### 3. Ruta de transiciones personalizadas

**Qué se decidió:**
Crear `RouteTransitions` con métodos estáticos para 4 tipos de transición:
fadeSlideUp, slideFromRight, slideFromBottom, slideReverse.

**Por qué se tomó esta decisión:**
`MaterialPageRoute` no permite personalizar la curva de animación ni
combinar fade + scale + slide. Las transiciones personalizadas dan un
toque cinematográfico premium.

**Alternativas descartadas:**
- Paquetes externos de animación de rutas — dependencia innecesaria
- Mantener `MaterialPageRoute` default — visualmente genérico

**Impacto en el código:**
Widget nuevo en `lib/widgets/route_transitions.dart` (76 líneas).
Todas las navegaciones en HomeScreen, GamesMenuScreen y SettingsScreen
ahora usan estas transiciones.

### 4. Sistema de partículas en NeonBackground

**Qué se decidió:**
Reemplazar los iconos flotantes (Icons.favorite, etc.) por un sistema de
partículas decorativas (círculos, corazones, estrellas) con opacidad muy
baja (0.03-0.12) y un gradiente de fondo animado.

**Por qué se tomó esta decisión:**
Los iconos flotantes se veían genéricos y tenían demasiado peso visual
para ser decorativos. Las partículas son más sutiles, elegantes y
cinematográficas.

**Alternativas descartadas:**
- Mantener iconos flotantes actuales — aspecto genérico
- Fondo estático sin animación — pérdida de personalidad

**Impacto en el código:**
`lib/widgets/neon_background.dart` reescrito completamente como
StatefulWidget. Se mantiene el parámetro `showIcons` como compatibilidad.

---

## Mapa de cambios

### Archivos nuevos

| Archivo | Propósito | Decisión clave asociada |
|---------|-----------|------------------------|
| `lib/widgets/neon_button.dart` | Botón reutilizable con 3 variantes (primary/secondary/ghost) | NeonButton en vez de _GlassButton |
| `lib/widgets/neon_toggle.dart` | Toggle personalizado con track redondo y thumb animado | Consistencia glassmorphism en Settings |
| `lib/widgets/game_card.dart` | Card glassmorphism para menú de juegos con glow de color | Cards con blur y borde sutil |
| `lib/widgets/route_transitions.dart` | 4 tipos de transición animada entre pantallas | Transiciones cinematográficas |

### Archivos modificados

| Archivo | Qué cambió | Por qué cambió |
|---------|-----------|---------------|
| `lib/core/theme/app_colors.dart` | Nueva paleta refinada, renombrado modeDuel → modeCharades | Colores más intensos y premium |
| `lib/core/constants/app_constants.dart` | glassBorderRadius 25→20, glassBlurSigma 10→15, maxIcons 10→15 | Alineado con especificación visual |
| `lib/core/theme/app_theme.dart` | Nuevo displaySmall (PlayfairDisplay), headlineSmall, tracking ajustado | Tipografía más rica para scores |
| `lib/widgets/glass_card.dart` | Parámetro accentColor + BoxShadow base | Soportar glow de color en GameCard |
| `lib/widgets/neon_background.dart` | Reescribir a StatefulWidget con partículas + gradiente animado | Fondo más elegante y cinematográfico |
| `lib/screens/home_screen.dart` | Rediseño completo con staggered animations y NeonButton | HomeScreen premium |
| `lib/screens/games_menu_screen.dart` | Glassmorphism cards, staggered entry, transiciones | Menú de juegos refinado |
| `lib/screens/settings_screen.dart` | Rediseño completo con GlassCard/NeonToggle/NeonButton | SettingsScreen consistente |

### Archivos eliminados

Ninguno.

---

## Cambios en archivos clave

### `lib/screens/home_screen.dart`

**Antes:** StatefulWidget con _GlassButton privado, badge con nombres,
divider neón, sin entrada animada.

**Después:** StatefulWidget con 2 AnimationControllers (glow + entry),
4 _AnimatedEntry con Interval escalonado, NeonButton en vez de
_GlassButton, transiciones RouteTransitions, badge con latido.

**Por qué es importante:** Es la primera pantalla que ve el usuario.
La entrada escalonada y las micro-interacciones marcan la diferencia
entre una app genérica y una premium.

### `lib/widgets/neon_background.dart`

**Antes:** StatelessWidget con gradiente + iconos flotantes (favorite,
whatshot, etc.) en bucle.

**Después:** StatefulWidget con AnimationController de 15s, 3 capas:
(1) gradiente con Alignment animado, (2) 15 partículas decorativas
con movimiento orgánico, (3) child content.

**Por qué es importante:** Este widget envuelve TODAS las pantallas
(16 usos). Cualquier cambio aquí afecta a toda la app.

---

## Criterios de éxito verificados

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| Staggered animations HomeScreen | ✅ Cumplido | 4 _AnimatedEntry con Interval 0-0.4, 0.2-0.6, 0.4-0.8, 0.6-1.0 |
| Badge con nombres reales | ✅ Cumplido | Lee settings.heName/sheName, defaults 'ÉL'/'ELLA' |
| Botones micro-interacciones | ✅ Cumplido | NeonButton primary: shimmer + glow + escala 1.02 |
| Cards glassmorphism en menú | ✅ Cumplido | GameCard usa GlassCard con blur + borde + glow |
| Staggered en cards del menú | ✅ Cumplido | animationDelay: index * 100ms (0-500ms) |
| SettingsScreen glassmorphism | ✅ Cumplido | GlassCard + NeonToggle + inputs neón |
| NeonBackground con partículas | ✅ Cumplido | 15 partículas (círculos, corazones, estrellas) + gradiente animado |
| Transiciones animadas | ✅ Cumplido | 4 tipos en RouteTransitions con easeInOutCubic |
| Nuevos widgets compartidos | ✅ Cumplido | NeonButton, GameCard, NeonToggle creados y usados |
| flutter analyze sin errores | ✅ Cumplido | 0 errors, 0 warnings (22 info hints) |
| No rotura funcionalidad | ✅ Cumplido | Controllers, providers, modelos, servicios sin modificar |
| HomeScreen actualiza nombres | ✅ Cumplido | context.watch + notifyListeners |

---

## Deuda técnica identificada

- `showIcons` en `NeonBackground` no tiene `@Deprecated` (aunque se mantiene para compatibilidad)
- `_AnimatedEntry` recrea `CurvedAnimation` en cada build; mejorable con caché
- 22 info hints del analyzer (prefer_const_constructors, etc.) — solo estilo

---

## Lo que el programador debe saber

- **Navegación actualizada**: las transiciones usan `RouteTransitions` en vez de `MaterialPageRoute` directo. Para nuevas pantallas, importar `route_transitions.dart` y usar el método correspondiente.
- **NeonBackground**: ahora es `StatefulWidget` con partículas. Si una pantalla necesita el fondo sin animación (p.ej. para rendimiento en dispositivos low-end), se puede agregar un flag `static` en el futuro.
- **NeonButton** reemplaza conceptualmente a `_GlassButton` (que fue eliminado). Para nuevos botones, usar `NeonButton` con la variante adecuada.
- **AppColors.modeCharades** reemplaza `modeDuel` (renombrado). Si algún archivo externo referencia `modeDuel`, actualizarlo.
- `flutter analyze` debe mantenerse limpio. Los 22 hints info son aceptables pero ideales de limpiar progresivamente.

---

## Reportes de ejecución

| Iteración | Archivo de reporte |
|-----------|-------------------|
| 1 | `reports/2026-05-30_visual-redesign_iter1.md` |

Para ver los diffs completos y los commits atómicos de cada paso,
consultar el reporte de ejecución individual listado arriba.
