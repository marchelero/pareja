import 'package:flutter/foundation.dart';
import '../core/constants/game_caps.dart';
import '../core/storage/local_storage.dart';
import '../core/utils/date_utils.dart' as utils;
import '../data/ad_service.dart';

/// Orquesta reglas de monetizacion: premium, caps diarios, rewarded ads.
///
/// **Source of truth**: `LocalStorage`. Provider hace caching en memoria y
/// re-persiste en cada cambio. Tests pueden mockear SharedPreferences via
/// `SharedPreferences.setMockInitialValues` y AdService pasando un fake.
class MonetizationProvider extends ChangeNotifier {
  /// Servicio de ads. Default [NoOpAdService] para tests / web / error de init.
  final AdService adService;

  /// Fuente de tiempo inyectable para testear rollover de dia. Default:
  /// [DateTime.now].
  final DateTime Function() _now;

  MonetizationProvider({AdService? adService, DateTime Function()? clock})
      : adService = adService ?? const NoOpAdService(),
        _now = clock ?? DateTime.now;

  bool _isPremium = false;
  bool _isLoaded = false;
  Map<String, int> _playCounts = <String, int>{};
  String _lastResetDateKey = '';

  bool get isPremium => _isPremium;
  bool get isLoaded => _isLoaded;

  /// Cuantas plays le quedan al juego en el dia. Retorna **-1** como sentinel
  /// para "sin limite" (juegos no-capped, o premium users).
  int remainingPlays(GameCap game) {
    _syncDayRollover();
    if (!game.isCapped) return -1;
    if (_isPremium) return -1;
    final used = _playCounts[game.displayName] ?? 0;
    final remaining = game.dailyCap - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// True si el usuario puede arrancar el juego ahora mismo.
  bool canPlay(GameCap game) {
    if (!game.isCapped) return true;
    if (_isPremium) return true;
    return remainingPlays(game) > 0;
  }

  /// Carga estado desde LocalStorage. Si hubo rollover de dia, limpia
  /// `_playCounts` para arrancar fresco.
  Future<void> load() async {
    _isPremium = await LocalStorage.isPremium();
    _lastResetDateKey = await LocalStorage.getLastResetDate();
    _playCounts = await LocalStorage.getPlayCounts();

    if (utils.DateUtils.isDayRollover(
      _lastResetDateKey.isEmpty ? null : _parseStoredDate(_lastResetDateKey),
      _now(),
    )) {
      _playCounts = <String, int>{};
      _lastResetDateKey = utils.DateUtils.dayKey(_now());
      await LocalStorage.savePlayCounts(_playCounts);
      await LocalStorage.setLastResetDate(_lastResetDateKey);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Persistir estado de premium. `setPremium(true)` y `setPremium(false)`
  /// se usan para testing y para el flujo real via BillingService.
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await LocalStorage.setIsPremium(value);
    notifyListeners();
  }

  /// Llamar DESPUES de EMPEZAR un juego. Incrementa el contador diario.
  /// Para juegos no-capped, igual se registra (para stats futuras).
  Future<void> recordPlay(GameCap game) async {
    _syncDayRollover();
    final name = game.displayName;
    _playCounts[name] = (_playCounts[name] ?? 0) + 1;
    _lastResetDateKey = utils.DateUtils.dayKey(_now());
    await LocalStorage.savePlayCounts(_playCounts);
    await LocalStorage.setLastResetDate(_lastResetDateKey);
    notifyListeners();
  }

  /// Suma +1 jugada gratis para el juego especifico. Decrementa el count
  /// en 1, lo cual aumenta `remainingPlays` en 1. Permite count negativo
  /// (representa "bonus plays banked" — user gano plays sin haber usado ninguna).
  /// Si el juego no tiene cap, es no-op.
  ///
  /// **Direct grant**: este metodo NO muestra un ad — solo aplica el bonus.
  /// Usar cuando ya se valido la recompensa externamente. Para el flow
  /// completo de "user mira ad → recibe bonus", usar [watchAdForGameWithReward].
  Future<void> watchAdForGame(GameCap game) async {
    if (!game.isCapped) return;
    _syncDayRollover();
    final name = game.displayName;
    _playCounts[name] = (_playCounts[name] ?? 0) - 1;
    _lastResetDateKey = utils.DateUtils.dayKey(_now());
    await LocalStorage.savePlayCounts(_playCounts);
    await LocalStorage.setLastResetDate(_lastResetDateKey);
    notifyListeners();
  }

  /// Flow completo: muestra rewarded ad via [adService], y SOLO si el user
  /// gano la recompensa, aplica el bonus de +1 jugada. Retorna true si
  /// el bonus fue aplicado, false si ad fallo, user no completo, o el juego
  /// no necesita rewarded (uncapped, premium).
  Future<bool> watchAdForGameWithReward(GameCap game) async {
    if (!game.isCapped) return false;
    if (_isPremium) return false; // premium no necesita ads
    final success = await adService.showRewardedAd();
    if (!success) return false;
    await watchAdForGame(game);
    return true;
  }

  /// Limpia contadores del dia. Util para QA y para "empezar de cero".
  Future<void> clearTodayCounts() async {
    _playCounts = <String, int>{};
    await LocalStorage.savePlayCounts(_playCounts);
    notifyListeners();
  }

  // ── Helpers ──

  /// Sincroniza el estado si cambió el día local. Se llama desde getters
  /// (solo muta estado en memoria, sin notifyListeners — el reader actual
  /// ya obtiene el valor corregido) y desde los métodos que persisten.
  void _syncDayRollover() {
    final today = utils.DateUtils.dayKey(_now());
    if (_lastResetDateKey == today) return;
    _playCounts = <String, int>{};
    _lastResetDateKey = today;
  }

  /// Convierte "YYYY-MM-DD" a DateTime local. Usado solo para chequeo
  /// de rollover; si la key no es valida, retorna null y fuerza reset.
  DateTime? _parseStoredDate(String dayKey) {
    try {
      final parts = dayKey.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}
