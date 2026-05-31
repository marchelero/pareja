# Nuevos Juegos: «Yo Nunca» y «Dígalo con Mímica»

> **Fecha:** 2026-05-30
> **Proyecto:** TWO PLAYERS
> **Estado:** Diseño aprobado — pendiente de implementación

---

## Resumen

Se reemplazan dos juegos existentes («Lo Más Probable» y «Duelo») por dos nuevos juegos con mecánicas distintas a cualquier juego actual de la app:

| Reemplaza | Nuevo juego | Mecánica |
|-----------|-------------|----------|
| Lo Más Probable 🧠 | **Yo Nunca** 💋 | Confesiones con votación YO/NUNCA |
| Duelo 🔫 | **Dígalo con Mímica** 🎭 | Actuación y adivinanza por turnos |

---

## 1. «Yo Nunca» (Never Have I Ever)

### 1.1 Concepto

Clásico juego de confesiones adaptado a pareja. Aparece una frase y cada jugador responde si **YO** (lo hizo) o **NUNCA** (no lo hizo). Si hay disparidad, quien dijo YO recibe un strike.

### 1.2 Setup (pantalla de inicio: `never_have_i_ever_start_screen.dart`)

- **Rondas:** 5 / 10 / 15 / 20
- **Puntos para ganar:** 3 / 5 / 7
- **Modo Hot:** OFF / ON (filtra frases por `isHot`)
- **Strikes por penitencia:** 3

### 1.3 Mecánica por ronda

```
1. Aparece frase: "Nunca he..."
2. Se muestra solo al jugador activo (fade/animación de transición)
3. Toca YO o NUNCA
4. Se oculta la pantalla brevemente → turno del otro jugador
5. Segundo jugador toca YO o NUNCA
6. Se revelan ambas respuestas con animación
```

**Resultados posibles:**

| ÉL | ELLA | Resultado |
|:---:|:---:|:---|
| YO | YO | ✅ Nadie recibe strike |
| NUNCA | NUNCA | ✅ Nadie recibe strike |
| YO | NUNCA | ⚡ Strike para ÉL |
| NUNCA | YO | ⚡ Strike para ELLA |

**Cada N strikes** (configurable, default: 3) → penitencia. Strikes se reinician.

**Puntaje:** +1 punto por ronda donde NO recibió strike. Gana quien llegue primero a los puntos configurados.

### 1.4 Datos (`assets/data/never_have_i_ever.json`)

```json
[
  { "id": 1, "text": "fingido un orgasmo", "isHot": true },
  { "id": 2, "text": "llorado viendo una película animada", "isHot": false },
  ...
]
```

### 1.5 Nuevos archivos

| Archivo | Propósito |
|---------|-----------|
| `lib/screens/never_have_i_ever/never_have_i_ever_start_screen.dart` | Setup con opciones |
| `lib/screens/never_have_i_ever/never_have_i_ever_game_screen.dart` | Pantalla de juego |
| `lib/controllers/never_have_i_ever_controller.dart` | Controlador ChangeNotifier |
| `lib/core/models/never_have_i_ever_question.dart` | Modelo de dato |
| `assets/data/never_have_i_ever.json` | 40-80 frases |

---

## 2. «Dígalo con Mímica» (Charades)

### 2.1 Concepto

Un jugador ve una palabra/frase en pantalla y debe representarla con gestos (sin hablar) mientras el otro adivina en un tiempo límite.

### 2.2 Setup (pantalla de inicio: `charades_start_screen.dart`)

- **Categorías** (checkbox múltiple):
  - Películas 🎬
  - Posiciones Sexuales 🔥 (solo en Hot)
  - Animales 🐾
  - Acciones Cotidianas 🏠
  - Celebridades ⭐
  - Comidas 🍕
  - Profesiones 👨‍🔧
- **Tiempo por ronda:** 30s / 45s / 60s
- **Puntos para ganar:** 3 / 5 / 7
- **Strikes por penitencia:** 5
- **Modo Hot:** OFF / ON (habilita categorías y palabras spicy)

### 2.3 Mecánica por ronda

```
1. Sale palabra/frase de categoría seleccionada
2. Se muestra SÓLO al mímico (texto grande, animación de entrada)
3. Mímico toca "¡EMPEZAR!" → timer arranca
4. Mímico voltea la pantalla hacia el adivinador
5. Mímico hace gestos (no habla, no señala objetos)
6. Dos outcomes:

   ✅ ADIVINA → +1 punto para el MÍMICO
   ❌ FALLA (tiempo se acaba) → sorteo de strike:
       ┌──────────────┬──────┐
       │ Resultado     │ Prob │
       ├──────────────┼──────┤
       │ ⚡ Strike ÉL │ 25%  │
       │ ⚡ Strike ELLA│ 25%  │
       │ ⚡⚡ Ambos   │ 25%  │
       │ ✅ Nadie     │ 25%  │
       └──────────────┴──────┘
```

**5 strikes acumulados** → penitencia. Strikes se reinician.

**Gana** quien llegue primero a los puntos configurados.

### 2.4 Datos (`assets/data/charades_words.json`)

```json
[
  { "id": 1, "word": "Titanic", "category": "peliculas", "isHot": false },
  { "id": 2, "word": "El misionero", "category": "posiciones_sexuales", "isHot": true },
  ...
]
```

### 2.5 Nuevos archivos

| Archivo | Propósito |
|---------|-----------|
| `lib/screens/charades/charades_start_screen.dart` | Setup con opciones |
| `lib/screens/charades/charades_game_screen.dart` | Pantalla de juego (mímica) |
| `lib/controllers/charades_controller.dart` | Controlador ChangeNotifier |
| `lib/core/models/charades_word.dart` | Modelo de dato |
| `assets/data/charades_words.json` | ~50 palabras por categoría |

---

## 3. Cambios en archivos existentes

| Archivo | Cambio |
|---------|--------|
| `lib/screens/games_menu_screen.dart` | Reemplazar tarjetas de "Lo Más Probable" y "Duelo" por "Yo Nunca" y "Dígalo con Mímica" |
| `lib/providers/settings_provider.dart` | Agregar métodos `saveNeverHaveIEverRound` y `saveCharadesOptions` si se desea persistir configuración |
| `.agents/PROJECT.md` | Actualizar lista de modos de juego y estructura |

---

## 4. Lo que NO cambia

- No se modifican JSON ni assets existentes
- No se agregan nuevas funcionalidades a otros juegos
- No se agregan tests automatizados
- Se mantiene el patrón Controller + Screen (ChangeNotifier)
- Se mantiene Provider como state management

---

## 5. Penitencias

Ambos juegos comparten el sistema de penitencias. Al alcanzar el límite de strikes, se muestra una penitencia aleatoria. Las penitencias se reutilizan de los retos existentes en `roulette_dare.json` y `drinks_tasks.json`, filtradas por tipo.

---

## 6. Consideraciones de UI/UX

- **Pantalla compartida:** Ambos juegos están diseñados para un solo dispositivo. En "Yo Nunca" se implementa un breve fade entre turnos para dar privacidad a la respuesta.
- **Timer visual:** En Mímica, el timer ocupa la mitad superior de la pantalla con una barra de progreso colorida (verde → amarillo → rojo).
- **Animación de strike:** Los strikes se muestran como íconos ⚡ que caen desde arriba con una sacudida.
- **Penitencias:** Modal con texto grande y efecto de celebración / castigo según corresponda.
