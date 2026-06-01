# Twoplayers — Plan de Mejoras Integral

**Fecha:** 2026-06-01
**Estado:** Aprobado

## Resumen

Plan de mejoras para la app Twoplayers (pareja), un juego de fiesta para parejas con 7 juegos implementados actualmente. Se abordarán 4 capas de mejora: limpieza, refactor, nuevo juego (Date Night Duel), y UX/UI.

---

## Capa 1: Limpieza

Objetivo: Eliminar código muerto y archivos temporales.

### Acciones
| Archivo | Acción |
|---------|--------|
| `assets/data/drinks_tasks.json.tmp` | Eliminar |
| `lib/models/most_likely_question.dart` | Eliminar (no usado) |
| Imports huérfanos a `most_likely_question` | Limpiar |

### Riesgos
Ninguno — solo eliminación de código no referenciado.

---

## Capa 2: Refactor

Objetivo: Reducir duplicación, mejorar separación de responsabilidades.

### Acciones
| Archivo/Área | Problema | Solución |
|---|---|---|
| `screens/roulette_screen.dart` | Estado perpetuo, timers no limpiados | Usar `TickerProviderStateMixin`, cancelar en `dispose` |
| `screens/coin_flip_screen.dart` | Código duplicado de ruleta | Extraer `RandomAnimationMixin` compartido |
| `screens/bomb_screen.dart` | Lógica de countdown mezclada con UI | Separar en `BombController` con Provider |
| `screens/drinks_screen.dart` | Tareas hardcodeadas | Migrar a `assets/data/drinks_tasks.json` |
| Varios screens | Navegación duplicada | Crear helper de navegación o adoptar GoRouter |

### Riesgos
Medio — requiere verificar que cada refactor no rompa funcionalidad existente. Se recomienda probar manualmente cada screen después del cambio.

---

## Capa 3: Juego Nuevo — Date Night Duel (Duelo Nocturno)

### Datos
- Fuente: `assets/data/duel_questions.json`
- Formato: preguntas con 2 opciones de respuesta

### Gameplay
1. Se muestra una pregunta con dos opciones
2. Cada jugador selecciona su opción en privado (oculto del otro)
3. Se revelan ambas respuestas simultáneamente
4. Se muestra si coincidieron o no
5. Sistema de puntaje: +1 por coincidir

### Screens
- `DuelScreen` — pantalla principal del juego
  - Modo pregunta (oculto, cada jugador ve solo su selección)
  - Modo revelación (ambas respuestas visibles)
  - Score acumulado

### Controller
- `DuelController` extends `BaseGameController`
- Estados: `asking`, `player1Answered`, `player2Answered`, `revealing`, `finished`
- Provider para estado compartido

### Integración
- Agregar entrada en `_games` en `HomeScreen`
- Usar mismo tema (neon/glassmorphism)

### Riesgos
Bajo — sigue el patrón existente de los otros juegos.

---

## Capa 4: UX/UI y Animaciones

### Transiciones entre screens
- Reemplazar `Navigator.push` default con `PageRouteBuilder` personalizado
- Slides: derecha → izquierda para navegación hacia adelante
- Escala + fade para modales

### Micro-interacciones
- Botones: `Transform.scale` con `GestureDetector` onTapDown/onTapUp
- Feedback táctil: `HapticFeedback.lightImpact()` en acciones clave

### Pantalla de inicio (HomeScreen)
- Staggered animation: juegos aparecen secuencialmente con fade + slide up
- `AnimatedOpacity` + `AnimatedSlide` con delays escalonados

### Resultados
- `AnimatedCounter` para scores (animación de conteo)
- `Confetti` widget (opcional, paquete externo o custom)

### Tema
- Mejorar consistencia del glassmorphism
- Estandarizar blur, opacidad y bordes en todos los glass containers
- Revisar contraste de texto sobre fondos neon

### Sonidos
- SFX en: selección de juego, acierto, error, fin de ronda
- Usar paquete `audioplayers` ya existente en el proyecto

### Riesgos
Bajo — cambios puramente de presentación, sin tocar lógica de negocio.

---

## Orden de Ejecución

1. **Limpieza** — sin dependencias, rápido
2. **Refactor** — sobre base limpia
3. **Date Night Duel** — después del refactor para seguir patrones mejorados
4. **UX/UI** — al final, sobre código ya estable

## Criterios de Éxito
- App compila sin errores después de cada capa
- Los 7 juegos existentes funcionan igual que antes (sin regresiones)
- Date Night Duel es completamente jugable
- Transiciones y animaciones se sienten suaves (60fps)
