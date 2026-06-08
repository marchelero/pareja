# Settings & Home Screen Improvements

> Diseño aprobado el 2026-06-08
> Proyecto: LovePlay

---

## Alcance

Mejorar la pantalla de configuración general y la pantalla principal con nuevas secciones y controles, sin agregar dependencias externas a pubspec.yaml.

---

## 1. Pantalla de Configuración — Nuevo orden

```
┌─ AppBar: "CONFIGURACIÓN"
│
├─ JUGADOR 1        ← sin cambios (nombres, género, color)
├─ JUGADOR 2        ← sin cambios (nombres, género, color)
├─ MODO             ← sin cambios (Pareja / Amigos)
├─ GUARDAR          ← botón movido aquí (justo después de MODO)
├─ AJUSTES DE JUEGO ← sección ampliada (ver §2)
├─ ESTADÍSTICAS     ← sección nueva (ver §3)
└─ Versión al pie
```

El botón GUARDAR ahora persiste nombres, modo invitado, y cualquier cambio pendiente de la sección jugadores. Se mueve justo después de MODO y antes de AJUSTES DE JUEGO.

---

## 2. Sección AJUSTES DE JUEGO — Contenido ampliado

Dentro de una GlassCard, en este orden:

| Control | Tipo | Estado inicial | Persistencia |
|---------|------|----------------|--------------|
| 🔊 Sonido | NeonToggle (on/off) | On | `sound_enabled` (bool) — existente |
| 📳 Vibración | NeonToggle (on/off) | On | `vibration_enabled` (bool) — existente |
| 🕐 Duración ronda (default) | Selector: 30s·45s·60s·90s·120s | 60s | `default_round_time` (int segundos) |
| 🕵️ Modo invitado | NeonToggle (on/off) | Off | `guest_mode` (bool) |

### Duración ronda default
- Almacena un entero (segundos) en SharedPreferences
- Los juegos que usan contador (A Tiempo, Rapid Fire) leerán este valor como default
- No reemplaza la configuración individual de cada juego, solo establece el default

### Modo invitado
- Cuando está activo, todos los game screens muestran "J1" / "J2" en lugar del nombre real
- No afecta la configuración ni los nombres guardados
- Implementación: getter `SettingsProvider.displayName1` / `displayName2` que retorna el nombre real o "J1"/"J2" según `_guestMode`

---

## 3. Sección ESTADÍSTICAS — Nueva

Datos almacenados en SharedPreferences:

| Estadística | Key | Tipo | Cálculo |
|-------------|-----|------|---------|
| Partidas jugadas | `stats_games_played` | int | Incrementa en 1 cada vez que un juego termina |
| Detalle por juego | `stats_game_<name>` | Map<String,int> | Contador por juego individual |
| Tiempo estimado | `stats_play_time_minutes` | int | Se incrementa ~15 min por partida |

El provider expone:
- `int totalGamesPlayed`
- `String? favoriteGameMode` — el juego con mayor contador
- `int estimatedPlayTimeMinutes`

### Visualización
```
┌─ GlassCard ──────────────────────────┐
│                                       │
│  🎮 Partidas totales:     42          │
│  🏆 Modo favorito:   Preguntas        │
│  ⏱️  Tiempo estimado:  10h 30m        │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  RESETEAR DATOS                 │  │
│  └─────────────────────────────────┘  │
│                                       │
└───────────────────────────────────────┘
```

### Botón RESETEAR DATOS
- Diálogo de confirmación: "¿Borrar todos los datos? Los nombres, colores y estadísticas volverán a sus valores de fábrica."
- Al confirmar: llama a `LocalStorage.clearAll()`, recarga defaults, notifica
- `LocalStorage.clearAll()` usa `prefs.clear()` (borra todas las SharedPreferences)

---

## 4. Pantalla Principal — Nombre VS Nombre en modo Amigos

### Cambio en `_buildNameBadge`

```
Current:
  [J1]  ❤️ (late)  [J2]       ← modo Pareja (sin cambios)
  [J1]    —         [J2]       ← modo Amigos (actual)

New:
  [J1]  ❤️ (late)  [J2]       ← modo Pareja (sin cambios)
  [J1]    VS        [J2]       ← modo Amigos (cambiado)
```

- Reemplazar `Icons.remove` por texto "VS" con estilo bold
- Mantener el lateo del corazón para modo Pareja
- Para modo Amigos: texto "VS" estático, sin animación

---

## 5. Archivos a modificar

| Archivo | Cambios |
|---------|---------|
| `lib/providers/settings_provider.dart` | Nuevos fields: guestMode, defaultRoundTime, stats; displayName1/displayName2 getters; incrementGamePlayed, resetAllData |
| `lib/core/storage/local_storage.dart` | Nuevos keys: guestMode, defaultRoundTime, stats keys; clearAll() |
| `lib/screens/settings_screen.dart` | Reordenar secciones; toggle guestMode; selector duración; sección estadísticas; botón resetear |
| `lib/screens/home_screen.dart` | VS text en modo Amigos |

| Todos los game screens (13) | Respetar `guestMode` (display names) |

---

## 6. Consideraciones técnicas


- **Stats tracking**: Se inyecta en el callback `onGameFinished` similar al patrón usado en QuestionsGameScreen
- **Guest mode**: Solo afecta display names, no la lógica interna de los juegos
- **Reset**: `SharedPreferences.getInstance()` → `prefs.clear()` + recargar defaults

---

## 7. No incluido (explicitamente fuera de alcance)

- Cambiar la sección JUGADOR 1 / JUGADOR 2
- Cambiar la sección MODO (Pareja/Amigos)
- Agregar sonidos nuevos o cambiar existing audio infrastructure
- Agregar paquetes a pubspec.yaml
- Modificar la lógica interna de los juegos (solo display names y stats)

---

## 8. Criterios de éxito

1. Settings screen reordenada: jugadores → modo → guardar → ajustes → estadísticas
2. Selector de duración default persistente
3. Toggle "Modo invitado" oculta nombres reales en game screens
4. Estadísticas se incrementan al terminar cada partida
5. Botón resetear borra todos los datos y recarga defaults
6. Home screen muestra "VS" en modo Amigos, corazón lateante en modo Pareja
7. `flutter analyze` → 0 issues
