# Rediseño Visual — TWO PLAYERS (Pareja)

> **Fecha:** 2026-05-30
> **Estado:** Aprobado para implementación
> **Dirección estética:** Neón Romántico Premium (Opción A)

---

## 1. Objetivo

Rediseñar la interfaz visual completa de la app TWO PLAYERS, refinando el estilo
neón romántico actual hacia una versión más premium, pulida y cinematográfica.
No se modifica lógica de juego, datos, ni funcionalidad existente.

## 2. Paleta de Color

### Colores base

| Rol | Color | Hex | Uso |
|-----|-------|-----|-----|
| Fondo principal | Negro puro | `#000000` | Scaffold, fondo base |
| Fondo secundario | Púrpura oscurísimo | `#0D0020` | Gradiente de fondo |
| Superficie | Púrpura oscuro | `#1A0A2E` | Cards, contenedores |
| Acento primario | Rosa neón | `#FF2D78` | Botón primario, glows, acentos |
| Acento secundario | Naranja | `#FF6B35` | Detalles, glows secundarios |
| Acento terciario | Púrpura vibrante | `#B44AFF` | Elementos decorativos |
| Texto primario | Blanco | `#FFFFFF` | Texto principal |
| Texto secundario | Blanco 70% | `#B3FFFFFF` | Subtítulos |

### Gradiente principal de fondo

```
begin: Alignment.topLeft
end: Alignment.bottomRight
colors: [#0D0020, #1A0030, #000000]
```

### Gradiente del botón primario

```
begin: Alignment.centerLeft
end: Alignment.centerRight
colors: [#FF2D78, #FF6B35]
```

## 3. Tipografía

| Estilo | Font | Weight | Size | Tracking | Uso |
|--------|------|--------|------|----------|-----|
| Decorativo | DancingScript | w700 | 86 | normal | Título "Date" |
| Heading 1 | Montserrat | w900 | 26 | 32 | "GAMES" |
| Heading 2 | Montserrat | w900 | 22 | 2 | Títulos de pantalla |
| Heading 3 | Montserrat | w800 | 18 | 1.5 | Títulos de sección |
| Body | Montserrat | w500 | 14 | 0.5 | Texto general |
| Label | Montserrat | w900 | 16 | 2 | Botones |
| Score | Playfair Display | w700 | 48 | normal | Puntajes numéricos |

## 4. Glassmorphism

Parámetros estándar para todos los elementos glass:

```dart
BoxDecoration(
  color: Colors.white.withAlpha(25),       // 10% opacidad
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: Colors.white.withAlpha(38),      // 15% opacidad
    width: 0.5,
  ),
)
// + backdropFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15)
// + sombra negra con blur 20, spread 2
```

## 5. HomeScreen

### Layout (vertical centrado)

```
Spacer(flex: 3)
  → Divider neón con glow pulsante
SizedBox(36)
  → Título "Date" (DancingScript 86, glow animado, parallax sutil)
  → "GAMES" (Montserrat 26, w900, tracking 32, gradiente horizontal)
SizedBox(36)
  → Divider neón con glow pulsante
SizedBox(14)
  → Badge de pareja: [NOMBRE ♥ NOMBRE] con animación de latido
Spacer(flex: 3)
  → Botón JUGAR (NeonButton primary, shimmer + glow + escala)
SizedBox(20)
  → Botón AJUSTES (NeonButton secondary, glass)
SizedBox(60)
```

### Animaciones de entrada (staggered)

1. **t=0ms**: Aparecen los dividers + título (fade-in 400ms)
2. **t=200ms**: Aparece el badge (fade-in + slide-up 400ms)
3. **t=400ms**: Aparece botón JUGAR (fade-in + slide-up 400ms)
4. **t=600ms**: Aparece botón AJUSTES (fade-in + slide-up 400ms)

### Badge de pareja

- Lee nombres desde `SettingsProvider` (heName, sheName)
- Defaults: "ÉL" / "ELLA" (definidos en `AppConstants`)
- Animación de latido en el icono ♥ con `AnimationController` + curva easeInOut
- Fondo glass con glow rosa pulsante sincronizado

### Botón JUGAR (NeonButton primary)

- Gradiente rosa→naranja
- Brillo shimmer que cruza horizontalmente (duración 4s)
- Glow pulsante sincronizado con el divider
- Escala 1.02 al presionar (InkWell con Transform)
- Sombra animada que se intensifica al presionar

### Botón AJUSTES (NeonButton secondary)

- Glassmorphism (sin gradiente de relleno)
- Borde blanco 15% opacidad
- Sin glow para diferenciarlo del primario
- Escala 1.02 al presionar

## 6. GamesMenuScreen

### AppBar
- Título "TWO PLAYERS • JUEGOS" (consistente con código actual)
- Montserrat w900, tracking 2, color blanco
- Fondo transparente con blur
- Sin elevation ni borde inferior

### Grid de juegos
- GridView.count con crossAxisCount: 2
- Padding: 20, spacing: 20
- 6 juegos en cards glassmorphism

### GameCard (widget reutilizable)

```
┌──────────────────┐
│                  │
│      ICONO       │  ← 60px, color blanco
│                  │
│     TÍTULO       │  ← Montserrat w800, 18px
│                  │
└──────────────────┘
```

- Fondo glass con color de acento aplicado como glow y borde (no relleno)
- Sombra: `BoxShadow(color: colorAcento.withAlpha(76), blurRadius: 15)`
- Animación de entrada escalonada por fila (fade-in + slide-up, 100ms de retardo entre cards)
- Efecto hover/press: elevación + intensificación del glow
- Cursor: pointer (web)

### Juegos y colores

| Juego | Icono | Color acento |
|-------|-------|-------------|
| Preguntas | `Icons.question_answer` | Naranja `#FF9800` |
| Ruleta | `Icons.casino` | Azul `#2196F3` |
| Chupitos | `Icons.local_bar` | Rojo vino `#8B0000` |
| Bomba | `Icons.timer` | Naranja intenso `#FF5722` |
| Yo Nunca | `Icons.psychology` | Teal `#009688` |
| Dígalo con Mímica | `Icons.theater_comedy` | Púrpura `#673AB7` |

## 7. SettingsScreen

### AppBar
- Título "CONFIGURACIÓN"
- Montserrat w900, tracking 2
- Botón de retroceso con icono blanco
- Fondo transparente

### Secciones (3)

1. **NOMBRES DE LA PAREJA**
   - Campo "Nombre de ÉL" con icono 👤 azul
   - Campo "Nombre de ELLA" con icono 👩 rosa
   - Input fields con estilo neón (borde inferior animado al focus)
   - Botón "GUARDAR NOMBRES" con gradiente rosa, feedback checkmark + snackbar

2. **AJUSTES DE JUEGO**
   - Toggle Sonido con icono 🔊 y track personalizado rosa
   - Toggle Vibración con icono 📳 y track personalizado rosa
   - Divider entre toggles

3. **PROGRESO**
   - Botón "Reiniciar Progreso de Ruleta" con icono 🔄
   - Diálogo de confirmación antes de reiniciar
   - Feedback con snackbar animado

## 8. NeonBackground (fondos)

### Capas (Stack)

1. **Fondo base**: Gradiente animado (tres colores que se desplazan lentamente)
   - Animación de 15s en bucle, movimiento diagonal sutil
2. **Partículas**: Sistema de partículas reemplazando iconos flotantes
   - Círculos luminosos pequeños (tamaño 3-8px) que flotan
   - Corazones neón en trayectorias curvas
   - Estrellas que titilan (opacidad variable)
   - Máximo 15 partículas, todas con opacidad 0.03-0.12
   - Colores: rosa neón, naranja, púrpura
3. **Child**: Contenido de la pantalla

## 9. Transiciones entre pantallas

| Ruta | Transición | Duración | Curva |
|------|-----------|----------|-------|
| Home → GamesMenu | Fade + scale (0.95→1.0) + slide-up 20px | 350ms | easeInOutCubic |
| Home → Settings | Slide desde derecha | 350ms | easeInOutCubic |
| GamesMenu → Juego | Slide desde abajo | 350ms | easeInOutCubic |
| Cualquier → atrás | Slide inverso | 300ms | easeInOutCubic |

Implementación: `PageRouteBuilder` personalizado con `transitionDuration` y
curva `Curves.easeInOutCubic`.

## 10. Widgets compartidos (refactor)

### NeonButton
```dart
class NeonButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final NeonButtonVariant variant; // primary, secondary, ghost
  final Color? accentColor;
  final double? glowIntensity;
}
```

### GlassCard
```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final double? blurIntensity;
}
```

### GameCard
```dart
class GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final int animationDelay; // para staggered animation
}
```

### SectionTitle
```dart
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
}
```

### NeonToggle
```dart
class NeonToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color? activeColor;
}
```

## 11. Archivos afectados

### Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/core/theme/app_colors.dart` | Nueva paleta con colores más refinados |
| `lib/core/theme/app_theme.dart` | Playfair Display para scores, tracking ajustado |
| `lib/screens/home_screen.dart` | Rediseño completo con staggered animations |
| `lib/screens/games_menu_screen.dart` | Cards glassmorphism, staggered entrada |
| `lib/screens/settings_screen.dart` | Glassmorphism, inputs neón, toggles personalizados |
| `lib/widgets/neon_background.dart` | Partículas en vez de iconos, gradiente animado |

### Creados

| Archivo | Propósito |
|---------|-----------|
| `lib/widgets/neon_button.dart` | Botón reutilizable con variantes |
| `lib/widgets/game_card.dart` | Card para menú de juegos |
| `lib/widgets/neon_toggle.dart` | Toggle personalizado |
| `lib/widgets/route_transitions.dart` | Transiciones personalizadas entre rutas |

## 12. Criterios de éxito

- [ ] HomeScreen muestra nombres reales desde SettingsProvider
- [ ] Animaciones staggered funcionan en HomeScreen y GamesMenu
- [ ] Botones tienen micro-interacciones (escala, glow, shimmer)
- [ ] Cards glassmorphism con blur real en GamesMenu
- [ ] Toggles personalizados en SettingsScreen
- [ ] Transiciones animadas entre todas las pantallas
- [ ] Partículas animadas en el fondo (máx 15, opacidad baja)
- [ ] `flutter analyze` sin errores ni warnings
- [ ] No se rompe ninguna funcionalidad de juegos existente
