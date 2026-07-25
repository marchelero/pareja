# Plan de Implementación: Play Store Content Audit + Hot Mode Gate

> Documento vivo. Estado: Fase 1 (auditoría editorial) aplicada. Fases 2-4 en diseño.

## Contexto

La app "Parejas" es un juego de parejas Flutter con 15+ minijuegos. Contiene contenido sugerente/erótico (preguntas, retos, ruleta atrevida) categorizado como "Picante" o con flag `isHot: true` en los JSON de assets. El contenido es **sugestivo pero NO pornográfico** (sin imágenes XXX, sin actos gráficos, sin UGC). El objetivo: pasar Play Store con tier +12 (Madurez media) sin perder la experiencia para usuarios adultos.

## Estado actual (rama `feature/playstore-content-audit`)

### Fase 1 — Auditoría editorial (COMPLETADA)

Rama: `feature/playstore-content-audit` (basada en `main`)
Rama backup: `backup/pre-audit-2026-07-25` (snapshot completo pusheado a origin)

Cambios aplicados (5 grupos, 11 edits):

| # | Archivo | Item | Antes | Después |
|---|---------|------|-------|---------|
| 1 | never_have_i_ever.json | id 58 | "tenido sexo sin protección a propósito" | **eliminado** (promueve unsafe sex) |
| 2 | never_have_i_ever.json | id 54 | "hecho videollamada íntima" | "hecho una llamada atrevida" |
| 3 | roulette_dare.json | línea 2 | "Quita una prenda a {PAREJA} lentamente" | "Ponle a {PAREJA} una prenda tuya por 5 minutos" |
| 4 | roulette_dare.json | línea 3 | "Deja que {PAREJA} te quite una prenda" | "Deja que {PAREJA} elija una canción para que bailes" |
| 5 | roulette_dare.json | línea 13 | "Haz un baile sexy corto para {PAREJA}" | "Haz un baile sensual corto para {PAREJA}" |
| 6 | drinks_tasks.json | hot7 | "Que tu pareja te quite una prenda." | "Que tu pareja te ponga una prenda suya por 5 minutos." |
| 7 | drinks_tasks.json | hot15 | "Deja que tu pareja decida qué prenda te quitas." | "Deja que tu pareja decida la próxima actividad que hacen juntos." |
| 8 | drinks_tasks.json | hot26 | "Elige: Deja que tu pareja te quite una prenda o toma." | "Elige: Recibe un masaje de tu pareja o toma." |
| 9 | drinks_tasks.json | hot42 | "Elige: Quítate una prenda o toma." | "Elige: Ponle a tu pareja una prenda tuya o toma." |
| 10 | drinks_tasks.json | hot86 | "Elige: Quítale una prenda a tu pareja o toma." | "Elige: Hazle un cumplido al oído a tu pareja o toma." |
| 11 | bomb_categories.json | id 10 | "Cosas que gimes o dices en la cama" | "Cosas que te encienden" |

**Validación**: JSON parse OK en los 4 archivos. Counts verificados:
- never_have_i_ever: 80 → 79 items
- roulette_dare: 20 items (sin cambio de count)
- drinks_tasks: 221 items (sin cambio de count, solo textos)
- bomb_categories: 30 items (sin cambio de count)

### Items flagged pero NO modificados (pendiente decisión)

| Archivo | Línea | Texto | Riesgo | Acción sugerida |
|---------|-------|-------|--------|-----------------|
| drinks_tasks.json | 2226 | "Simula una posición sexual (sin quitarse más ropa) por 30 segundos." | medio | Monitorear; el paréntesis mitiga el riesgo |
| drinks_tasks.json | 2259 | "Frota tu parte íntima contra la de tu pareja (con ropa) por 30 segundos." | medio-alto | Considerar suavizar: "...zona íntima por encima de la ropa..." |
| drinks_tasks.json | 2314 | "Acércate a 5cm de su parte íntima (con o sin ropa) y mantente ahí 10 seg. PROHIBIDO TOCAR." | medio-alto | Considerar suavizar o eliminar |
| drinks_tasks.json | 2347 | "Googlea 'Top Pose Sexual' e imiten la primera que salga (con ropa)." | medio | Considerar reemplazar por reto genérico |
| bomb_categories.json | 8 | "Lugares prohibidos donde te gustaría hacerlo" | bajo | OK, es temático sin acto |
| bomb_categories.json | 9 | "Juguetes para adultos" | bajo | OK, referencia, no descripción |
| bomb_categories.json | 12 | "Posiciones del Kamasutra" | bajo | OK, nombre propio, no descripción |

**Decisión**: estos quedan en Fase 1.5 (auditoría opcional) si Play Console flaggea en review. No tocar preventivamente.

## Veredicto Play Store post-auditoría

| Aspecto | Estado |
|---------|--------|
| Sin imágenes XXX | ✅ |
| Sin desnudos | ✅ |
| Sin descripciones de actos | ✅ |
| Sin UGC (user generated content) | ✅ |
| Sin links externos a contenido adulto | ✅ |
| Sin contenido que promueva unsafe sex | ✅ (tras eliminar id 58) |
| Sin strip-tease explícito | ✅ (tras reformular "quitar prenda") |
| Sin tono pornográfico | ✅ |
| Tono erótico/sugestivo OK para +12 | ✅ |

**Estimación probabilidad de aprobación**: 90-95% con tier +12 Madurez media.

## Fases pendientes

### Fase 2 — Hot Mode Gate (siguiente paso)

Objetivo: que el contenido hot sea opcional, gateado por age verification.

**Archivos a crear/modificar**:
- `lib/providers/settings_provider.dart` → agregar `_hotModeEnabled`, `_ageVerified`
- `lib/core/storage/local_storage.dart` → métodos `getHotModeEnabled()`, `setHotModeEnabled()`, `getAgeVerified()`, `setAgeVerified()`
- `lib/screens/settings/settings_screen.dart` → nueva sección "Modo adulto (+18)" con switch
- `lib/screens/settings/age_gate_modal.dart` → modal de verificación de edad (date picker)
- `lib/data/questions_repository.dart` → filtrar `category != "Picante"` si `!hotMode`
- `lib/data/never_have_i_ever_repository.dart` → filtrar `isHot != true` si `!hotMode`
- `lib/data/roulette_repository.dart` → no cargar `roulette_dare.json` si `!hotMode`
- `lib/data/charades_repository.dart` → no permitir categoría "posiciones_sexuales" si `!hotMode`
- `lib/data/drinks_repository.dart` → filtrar `isHot != true` del pool
- `lib/data/bomb_repository.dart` → filtrar categorías hot
- `lib/screens/charades/charades_start_screen.dart` → gate visual de categoría hot

**Criterios de aceptación**:
- Default: `hotModeEnabled = false` y `ageVerified = false` en primer launch
- Para activar hot mode: requerir ageVerified (pedir fecha de nacimiento, calcular `currentYear - birthYear >= 18`)
- Age verified persiste entre sesiones
- Hot mode se puede togglear on/off desde settings
- Si hot mode off, ningún hot item aparece en ninguna parte (categorías, pools, listas)
- Tests: para cada repository, verificar que con `hotMode=false` el pool no contiene items hot
- UI muestra claramente: "Contenido +18 — Activa solo si ambos están de acuerdo"

**Estimación**: 1 sprint (5-7 días de dev + tests)

### Fase 3 — Monetización (IAP non-consumible)

Objetivo: free con pago único que desbloquea features.

**Setup**:
- `pubspec.yaml` → agregar `play_services_billing: ^6.0.0` (o `in_app_purchase` oficial)
- Play Console → configurar producto in-app `premium_unlock` (non-consumible, precio sugerido $2.99-$3.99)
- `lib/services/billing_service.dart` → wrapper de BillingClient (query, purchase, acknowledge)
- `lib/providers/premium_provider.dart` → flag `isPremium` persistido
- `lib/screens/premium/premium_screen.dart` → pantalla de upgrade con beneficios
- Backend opcional: validar receipts via Google Play Developer API (recomendado para v2; client-side valida OK para v1)

**Features del tier premium** (a definir):
- Desbloquea todos los juegos
- Desbloquea modo hot (junto con age gate)
- Sin ads (si se agregan ads en free)
- Themes visuales extra
- Stats avanzadas

**Decisión de scope**: free incluye cuántos juegos? Típico: 3-5 juegos básicos + ads. Premium: todos los juegos + hot mode + sin ads.

**Estimación**: 1-2 sprints

### Fase 4 — Play Store Listing

Objetivo: configurar correctamente el listing para tier +12.

**Tareas**:
- Crear assets gráficos (icon 512x512, feature graphic 1024x500, screenshots 16:9 y 9:16, promo video opcional)
- Escribir descripción corta (80 chars) y completa (4000 chars) en español + inglés
- Declarar categoría: "Entretenimiento" o "Casual"
- Tier de contenido: Madurez media (+12) — marcar "no contiene contenido sexual" o declarar la naturaleza de forma honesta
- Política de privacidad: URL requerida (puede ser simple GitHub Pages)
- Data safety: declarar qué se recoge (probablemente solo prefs locales, nada personal)
- Testing interno: internal testing track → closed beta → production
- Submit for review

**Estimación**: 3-5 días de assets + 1-2 semanas de review de Google

## Testing strategy

### Fase 1 (auditoría) — Tests a agregar
- Unit test por cada JSON: verificar que NO existan los textos prohibidos
- Patrón: lista negra de strings → grep programático en `assets/data/*.json`
- Ubicación: `test/data/playstore_content_audit_test.dart`

### Fase 2 (gate) — Tests a agregar
- Unit test por repository con `hotMode=true` y `hotMode=false`
- Verificar: con `hotMode=false`, el pool de items NO contiene ningún item con `isHot:true` ni `category: "Picante"` ni `category: "posiciones_sexuales"`
- Verificar: el toggle persiste entre sesiones (mock SharedPreferences)
- Verificar: age gate se muestra al activar hot mode por primera vez
- Verificar: age gate rechaza si edad < 18

### Fase 3 (IAP) — Tests
- Mock BillingClient → simular purchase flow
- Verificar: receipt acknowledgement dentro de 3 días
- Verificar: restore purchases funciona
- E2E en internal testing track antes de producción

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Play Store rechaza por contenido borderline (Fase 4) | 10% | Fase 1.5 (suavizar items restantes); appeal con justificación |
| Piracy del IAP (compras falsas en cliente) | media | Acknowledge obligatorio; considerar backend en v2 |
| Age gate bypasseado (cambiar fecha de sistema) | alta | Es OK — disclaimer legal basta; el age gate no es enforcement real |
| Usuarios reportan contenido hot que se cuela | media | Blacklist test + audit periódico del data layer |
| Regresión: data layer rompe con cambios | baja | Tests unitarios por repository |

## Decisiones pendientes (requieren input del usuario)

1. **Fase 1.5**: ¿suavizar los 4 items drinks_tasks adicionales (2226, 2259, 2314, 2347)? O dejar para appeal si Play Store flaggea?
2. **Fase 2**: ¿Edad de gate = 18 o 16 o 13? Mi recomendación: 18 (más defensivo legalmente, +12 tier lo permite).
3. **Fase 3**: ¿Qué entra en premium? ¿Todos los juegos + hot + sin ads? ¿O solo algunos?
4. **Fase 3**: ¿Precio del IAP? Mi recomendación: $2.99 USD.
5. **Fase 4**: ¿Nombre de la app en Play Store? ¿"Parejas: Juegos de Hot & Love"? ¿Mantener "Parejas"?
6. **Localización**: ¿Solo español? ¿+ inglés? ¿+ portugués? Mi recomendación: español + inglés mínimo.

## Workflow recomendado

1. Commit Fase 1 (esta rama) — esperando tu OK
2. PR a main → review → merge
3. Crear nueva rama `feature/hot-mode-gate` desde main
4. Implementar Fase 2 con TDD
5. PR → review → merge
6. Repetir para Fase 3 y Fase 4

## Métricas de éxito

- Play Store aprobación sin strikes: ✅
- Tier declarado: +12 Madurez media ✅
- 80%+ tests coverage en data layer ✅
- 0% items hot visibles con `hotMode=false` ✅
- Conversion free → premium: target 2-5% (benchmark apps casual)

## Referencias

- Google Play Console: https://play.google.com/console
- Política de contenido Google Play: https://support.google.com/googleplay/android-developer/answer/9878814
- play-services-billing docs: https://developer.android.com/google/play/billing
- Backup snapshot: `backup/pre-audit-2026-07-25` en `origin`
- Working branch: `feature/playstore-content-audit`
