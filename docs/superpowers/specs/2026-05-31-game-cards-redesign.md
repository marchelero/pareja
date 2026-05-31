# Especificación: Rediseño de Game Cards (Menú Principal)

**Fecha:** 2026-05-31
**Estado:** Aprobado por el usuario
**Modo:** Orquestador → Planner → Executor → Auditor

---

## Problema

Las 6 cards del menú de juegos (`GamesMenuScreen`) ocupan demasiado espacio vertical.
El layout actual usa `GridView` con `crossAxisCount: 2` y `childAspectRatio: 0.85`,
con cada card mostrando un icono grande (44px) arriba y el título abajo, resultando
en cards de ~160px de alto. En una pantalla típica de 800px de alto usable, las cards
ocupan casi todo el viewport sin dejar espacio visual para respirar.

## Solución

Cambiar el layout de cada card de **vertical** (icono arriba + título abajo) a
**horizontal compacta** (icono a la izquierda + título a la derecha), reduciendo
el alto de cada card a ~70px y ocupando menos de la mitad del viewport.

## Diseño visual

### Layout del grid

```
┌──────────────────────────────────────┐
│ ┌────────────────────────────────┐   │
│ │ [icon]  Preguntas              │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ [icon]  Ruleta                 │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ [icon]  Chupitos               │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ [icon]  Bomba                  │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ [icon]  Yo Nunca               │   │
│ └────────────────────────────────┘   │
│ ┌────────────────────────────────┐   │
│ │ [icon]  Dígalo con Mímica      │   │
│ └────────────────────────────────┘   │
└──────────────────────────────────────┘
```

### Card individual

```
┌─────────────────────────────────────┐
│  ┌──────┐                           │
│  │ icon │  Título del juego         │
│  │ 28px │  (Montserrat w800 15px)  │
│  └──────┘                           │
└─────────────────────────────────────┘
```

### Especificaciones técnicas

| Propiedad | Valor |
|-----------|-------|
| `childAspectRatio` | 1.5 |
| Alto de card | ~70px |
| Icono | 28px, dentro de contenedor circular con glow del color del juego |
| Título | Montserrat w800, 15px, color blanco 95% |
| Gradiente fondo | LinearGradient topLeft→bottomRight con el color del juego (20%→5%→8%) |
| Borde | Color del juego al 35% opacity, width 1.5, borderRadius 16 |
| Sombra exterior | Glow del color del juego (blur 14) + sombra de profundidad negra |
| Espaciado grid | `mainAxisSpacing: 12`, `crossAxisSpacing: 0`, padding verical reducido |
| Feedback táctil | `InkWell` con `splashColor` y `highlightColor` del color del juego |
| Animación entrada | `TweenAnimationBuilder` 500ms + delay escalonado |

### Colores por juego (sin cambios)

| Juego | Color |
|-------|-------|
| Preguntas | `#FF9800` (naranja) |
| Ruleta | `#2196F3` (azul) |
| Chupitos | `#8B0000` (rojo oscuro) |
| Bomba | `#FF5722` (naranja intenso) |
| Yo Nunca | `#009688` (teal) |
| Dígalo con Mímica | `#673AB7` (púrpura) |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/widgets/game_card.dart` | Reescribir `build()`: layout horizontal, icono 28px con glow, aspecto ratio ajustado |
| `lib/screens/games_menu_screen.dart` | Ajustar `childAspectRatio: 1.5`, espaciado vertical reducido, padding del grid |

## Criterios de éxito

- [ ] Las cards ocupan ~50% menos de espacio vertical que antes
- [ ] Icono + título son legibles sin truncarse
- [ ] Cada card mantiene su color distintivo y glow neón
- [ ] La animación de entrada sigue funcionando con delays escalonados
- [ ] `flutter analyze` sin errores ni warnings
- [ ] El grid se ve equilibrado en pantallas de 360px a 430px de ancho

## No está en alcance

- No se cambia la lógica de navegación
- No se modifican otros screens
- No se agregan dependencias externas
- No se cambian los colores de los juegos
