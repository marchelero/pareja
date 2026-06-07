# Yo Nunca — Rediseño de UX

## Problema

El juego "Yo Nunca" no se entiende bien. Los usuarios encuentran confusos:

- Las respuestas "YO" / "NUNCA" (no es claro qué significan)
- El flujo de turnos (quién responde cuándo)
- Las reglas de puntuación (quién gana puntos y por qué)
- El resultado de cada ronda (qué pasó exactamente)

## Objetivo

Rediseñar la experiencia del juego para que sea clara e intuitiva, manteniendo las mecánicas actuales sin cambios en la lógica del juego.

## Enfoques considerados

- **A**: Claridad máxima (botones "SÍ, LO HE HECHO" / "NO, NUNCA", pregunta clara, resultado explicado)
- **B**: A + mini tutorial accesible durante el juego
- **C**: Interfaz tipo swipe (Tinder-style), más compleja

Se eligió **enfoque B**.

## Diseño

### Botón de ayuda [?]

- Círculo con "?" siempre visible en el AppBar (junto al marcador)
- Al hacer tap → modal con las reglas del juego
- El modal debe estar disponible en todo momento, no solo en la primera ronda
- Contenido del modal:

```
╔══════ REGLAS ═══════╗
║                     ║
║ 1. Se muestra una   ║
║    pregunta.         ║
║                     ║
║ 2. Cada jugador      ║
║    responde por      ║
║    turno:            ║
║                     ║
║  SÍ → lo he hecho   ║
║  NO → nunca lo he   ║
║       hecho         ║
║                     ║
║ 3. RESULTADO:       ║
║                     ║
║  Si uno dice SÍ     ║
║  y el otro NO →     ║
║  el que dijo NO     ║
║  gana 1 punto 🏆    ║
║                     ║
║  Si ambos dicen     ║
║  igual → nadie      ║
║  gana puntos        ║
║                     ║
║ 4. 3 strikes →      ║
║    penitencia ⚡     ║
║                     ║
║  [CERRAR]           ║
╚═════════════════════╝
```

### Layout de juego (de arriba a abajo)

1. **AppBar**
   - Botón [X] para salir
   - ScoreBoard (puntos de cada jugador)
   - Botón de ayuda [?]

2. **Info de ronda**
   - "RONDA X de Y"

3. **Indicador de strikes**
   - Nombre de cada jugador con ⚡ rellenos/vacíos

4. **Pregunta**
   - Label: "¿NUNCA HAS...?"
   - Texto de la pregunta en grande: "comido un insecto?"
   - Con animación de entrada (AnimatedSwitcher, mantener la actual)

5. **Indicador de turno**
   - Label con el nombre del jugador actual: "TURNO DE [NOMBRE]"
   - Con color del jugador (animated container)

6. **Botones de respuesta** (solo visibles durante el turno del jugador activo)
   - "SÍ, LO HE HECHO" — estilo primary con color del jugador
   - "NO, NUNCA" — estilo secondary gris

   Ambos botones usan emoji inline:
   - SÍ: 👍 o 🤷 (lo hizo)
   - NO: 🙅 (nunca lo hizo)

7. **Botón REVELAR** (cuando ambos ya respondieron)

8. **Resultado de la ronda**
   - Si disparidad: "🏆 [Jugador] gana 1 punto" + "⚡ Strike para [Jugador]"
   - Si paridad: "✅ +1 punto para cada uno" (ambos respondieron igual, actual)

9. **Botón SIGUIENTE RONDA**

### Flujo completo

1. Se muestra la pregunta → "TURNO DE [Player 1]"
2. Player 1 toca "SÍ, LO HE HECHO" o "NO, NUNCA"
3. → "TURNO DE [Player 2]"
4. Player 2 toca "SÍ, LO HE HECHO" o "NO, NUNCA"
5. → Botón "REVELAR"
6. Se muestra el resultado con explicación
7. Botón "SIGUIENTE RONDA"
8. Se repite

### Penitencia (sin cambios)

- Cuando un jugador llega a 3 strikes, se muestra el mismo diálogo actual
- Al cerrar, los strikes vuelven a 0

### Fin del juego (sin cambios)

- GameResultScreen actual

### Cambios técnicos

- Renombrar variables internas del controller:
  - `_heAnswered` → `_player1Answered`
  - `_sheAnswered` → `_player2Answered`
  - `_heSaidYo` → `_player1SaidYes`
  - `_sheSaidYo` → `_player2SaidYes`
  - `_scoreHe` → `_scorePlayer1`
  - `_scoreShe` → `_scorePlayer2`
  - `_strikesHe` → `_strikesPlayer1`
  - `_strikesShe` → `_strikesPlayer2`
  - Métodos: `answerHe(true)` → `answerPlayer1(true)`, etc.

- No cambiar métodos/firmas del constructor, solo nombres internos

### No cambia

- Mecánica del juego (quién gana puntos, cómo funcionan los strikes)
- Hot mode
- Sistema de penitencias
- Carga de preguntas desde JSON
- Pantalla de inicio
- Pantalla de resultado final
