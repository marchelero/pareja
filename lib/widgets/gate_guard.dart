import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/game_caps.dart';
import '../providers/monetization_provider.dart';
import 'play_limit_modal.dart';

/// Resultado de [GateGuard.tryStart] — la pantalla usa esto para decidir
/// si navega al juego o se queda.
enum GateResult {
  /// Puede jugar. La pantalla debe proceder a inicializar el controller
  /// y navegar al game screen.
  allowed,

  /// Bloqueado. La pantalla debe hacer nada (el modal ya se mostro,
  /// el user decidio no continuar).
  blocked,
}

/// Punto de inyeccion unico para la regla "podes jugar este juego?".
/// Llamado desde el boton EMPEZAR de cada `*_start_screen.dart`.
///
/// Comportamiento:
/// - Si [MonetizationProvider.canPlay] es true: registra la jugada, retorna
///   [GateResult.allowed].
/// - Si es false: muestra [PlayLimitModal]. Si el user vio un anuncio,
///   registra la jugada y retorna allowed. Si cerro el modal o toco
///   "Obtener Premium", retorna [GateResult.blocked].
class GateGuard {
  GateGuard._();

  /// Funcion pura (testable sin UI): decide que hacer dado el estado del
  /// provider y el juego. NO toca UI, NO llama a recordPlay.
  static GateDecision evaluate(MonetizationProvider monetization, GameCap game) {
    if (monetization.canPlay(game)) {
      return GateDecision.allow;
    }
    return GateDecision.showModal;
  }

  /// API de produccion: evalua + ejecuta side effects (recordPlay, modal).
  /// Usar en el onPressed del boton EMPEZAR.
  static Future<GateResult> tryStart(
    BuildContext context,
    GameCap game,
  ) async {
    final monetization = context.read<MonetizationProvider>();

    if (evaluate(monetization, game) == GateDecision.allow) {
      await monetization.recordPlay(game);
      return GateResult.allowed;
    }

    // Bloqueado: mostrar modal.
    if (!context.mounted) return GateResult.blocked;
    final modalResult = await PlayLimitModal.show(context, game);
    if (!context.mounted) return GateResult.blocked;

    switch (modalResult) {
      case PlayLimitResult.watchedAd:
        // User gano +1 play via ad. Registrar y permitir.
        await monetization.recordPlay(game);
        return GateResult.allowed;
      case PlayLimitResult.upgrade:
      case PlayLimitResult.dismissed:
        return GateResult.blocked;
    }
  }
}

/// Decision interna de [GateGuard.evaluate] — separada de [GateResult]
/// para mantener `evaluate` pura (sin side effects).
enum GateDecision {
  /// Permitir jugar sin intervencion.
  allow,

  /// Mostrar modal antes de decidir.
  showModal,
}
