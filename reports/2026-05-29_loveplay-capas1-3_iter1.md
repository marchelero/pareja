# Reporte de Iteración — Capas 1-3 TWO PLAYERS

**Fecha:** 2026-05-29  
**Iteración:** 1  
**Estado:** ✅ COMPLETADO

---

## Resumen

Se ejecutó el plan técnico de refactor de Capas 1-3 (Tema + Constantes + Estructura, Providers + Servicios, Widgets compartidos).

## Archivos creados/modificados

### Nuevos

| Archivo | Propósito |
|---------|-----------|
| `lib/core/theme/app_colors.dart` | Paleta centralizada de colores |
| `lib/core/theme/app_theme.dart` | ThemeData dark con GoogleFonts |
| `lib/core/constants/app_constants.dart` | Constantes del proyecto |
| `lib/app.dart` | MaterialApp con tema unificado |
| `lib/services/audio_service.dart` | Provider de audio (ChangeNotifier) |
| `lib/services/haptics_service.dart` | Hápticos estáticos multiplataforma |
| `lib/providers/settings_provider.dart` | Provider de settings (ChangeNotifier) |
| `lib/widgets/glass_card.dart` | Widget glassmorphism reutilizable |
| `lib/widgets/game_button.dart` | Botón con variantes primary/secondary/danger |
| `lib/widgets/section_title.dart` | Título sección con ícono |
| `lib/widgets/score_board.dart` | Marcador (ÉL vs ELLA) |

### Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/main.dart` | Reemplazado ParejaApp inline → MultiProvider + App |
| `pubspec.yaml` | Agregada dependencia `provider: ^6.1.2` |
| `lib/widgets/neon_background.dart` | Iconos reducidos 15→10 vía AppConstants, envuelto con RepaintBoundary |
| `test/widget_test.dart` | Actualizado a App + HomeScreen |

## Validación

- ✅ `flutter analyze` — **0 errores** (242 issues info/warning pre-existentes)
- ✅ `flutter pub get` — sin conflictos

## Próximos pasos

Capa 4 (Refactor de juegos) y Capa 5 (Estandarización visual).

---

## Auditoría — Capas 1-3

**Auditor:** Agente Auditor  
**Referencia:** commit `a974b3d`  
**Base:** Buenas prácticas generales de Flutter/Dart — no se encontraron skills específicas del proyecto.

### Puntos Auditados

| # | Criterio | Skill | Veredicto | Commits |
|---|----------|-------|-----------|---------|
| 1 | Estructura de carpetas coherente con el stack | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 2 | Uso correcto de Provider (ChangeNotifier, `notifyListeners`) | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 3 | Widgets reutilizables (sin lógica de negocio) | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 4 | Manejo de recursos (`AssetSource`, disposal de controladores) | General Flutter/Dart | ⚠️ Observación | a974b3d |
| 5 | Separación de responsabilidades (tema vs servicios vs widgets) | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 6 | Convenciones de nomenclatura Dart | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 7 | Manejo de errores en operaciones asíncronas | General Flutter/Dart | ⚠️ Observación | a974b3d |
| 8 | Uso de constantes en lugar de strings mágicos | General Flutter/Dart | ⚠️ Observación | a974b3d |
| 9 | Dispose de recursos (`AudioPlayer`, `AnimationController`) | General Flutter/Dart | ✅ Aprobado | a974b3d |
| 10 | Uso de `const` constructores donde sea posible | General Flutter/Dart | ✅ Aprobado | a974b3d |

### Detalle de fallas / observaciones

#### ⚠️ #4 — Manejo de recursos (`AssetSource`, disposal)

- `AppConstants.assetSounds = 'assets/sounds/'` incluye el prefijo `assets/` que NO debe usarse con `AssetSource`. El método `_play` ignora esta constante y hardcodea `'sounds/$fileName'`. La constante es engañosa y está muerta.
- **Acción sugerida:** Cambiar `assetSounds` a `'sounds/'` y usarlo en `_play`: `AssetSource('${AppConstants.assetSounds}$fileName')`.

#### ⚠️ #7 — Manejo de errores en operaciones asíncronas

- `SettingsProvider.load()` (`settings_provider.dart:20-30`) no tiene bloque `try-catch`. Si `SharedPreferences.getInstance()` lanza una excepción (raro pero posible en plataforma), el provider queda en estado inconsistente (`_isLoaded = false`, datos parciales).
- Los métodos `saveNames`, `toggleSound`, `toggleVibration`, `incrementRouletteSpin`, `resetRouletteProgress` tampoco manejan errores de persistencia.
- **Acción sugerida:** Agregar `try-catch` en `load()` y propagar o registrar errores. Considerar un estado `hasError` en el provider.

#### ⚠️ #8 — Uso de constantes en lugar de strings mágicos

- `GameButton` usa `sigmaX: 10, sigmaY: 10` directamente en lugar de `AppConstants.glassBlurSigma`.
- `GlassCard` usa `EdgeInsets.all(20)` como valor fijo en el default del constructor; podría extraerse a constante.
- Varios valores numéricos en `GameButton` (shimmer `widthFactor: 2.0`, `Alignment(-2.0 + t * 4.0, 0.0)`, `blurRadius: 15`, `spreadRadius: 1`, tamaños de íconos) y `ScoreBoard` (`fontSize: 20`, padding `15, 8`) están hardcodeados sin constante nominal.
- **Acción sugerida:** Migrar valores de estilo reutilizables a `AppConstants` progresivamente. Los valores puramente estéticos y locales pueden mantenerse si son idiomáticos del widget.

### Resumen ejecutivo

| Concepto | Valor |
|----------|-------|
| **Criterios aprobados** | 7 de 10 |
| **Observaciones** | 3 (leves) |
| **Fallas críticas** | 0 |
| **Acción requerida** | Revisar y corregir observaciones #4, #7 y #8 en próxima iteración |
| **Deuda técnica identificada** | Constante `assetSounds` engañosa; falta try-catch en operaciones asíncronas de `SettingsProvider`; valores mágicos menores en widgets |

**Conclusión general:** El commit `a974b3d` cumple con las buenas prácticas de Flutter/Dart en un 70% de los criterios sin fallas críticas. Las 3 observaciones son correcciones menores que no bloquean el avance a Capa 4.
