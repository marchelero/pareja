import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/game_caps.dart';
import '../providers/monetization_provider.dart';
import '../screens/paywall/paywall_screen.dart';

/// Resultado de [PlayLimitModal.show]. El modal se cierra via Navigator.pop
/// con uno de estos valores.
enum PlayLimitResult {
  /// El user vio un anuncio rewarded. Gano +1 jugada para el juego.
  watchedAd,

  /// El user toco "Obtener Premium" — la pantalla debe haber navegado
  /// a [PaywallScreen]. El gate retorna blocked de todas formas; el user
  /// puede comprar y volver a intentar.
  upgrade,

  /// El user cerro el modal sin elegir (back, tap outside, cancelar).
  dismissed,
}

/// Modal/bottom sheet que se muestra cuando el user agoto sus jugadas
/// diarias de un juego capped.
///
/// **v1 (Phase 3.2)**: el boton "Ver anuncio" llama directamente a
/// [MonetizationProvider.watchAdForGame]. En Phase 3.3, AdService reemplaza
/// esa llamada con un rewarded ad real de AdMob.
///
/// **v1 (Phase 3.2)**: "Obtener Premium" navega a [PaywallScreen] stub.
/// En Phase 3.4, PaywallScreen usa BillingService para IAP real.
class PlayLimitModal {
  PlayLimitModal._();

  /// Muestra el modal. Retorna cuando el user elige una opcion o dismiss.
  /// Retorna [PlayLimitResult.dismissed] si se cerro sin elegir.
  static Future<PlayLimitResult> show(
    BuildContext context,
    GameCap game,
  ) async {
    final result = await showModalBottomSheet<PlayLimitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => _PlayLimitSheet(game: game),
    );
    return result ?? PlayLimitResult.dismissed;
  }
}

class _PlayLimitSheet extends StatelessWidget {
  final GameCap game;

  const _PlayLimitSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final cap = game.dailyCap;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.pinkAccent, width: 2),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.pinkAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Sin jugadas restantes!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ya jugaste las $cap veces de hoy en ${game.displayName}.\n'
              'Volvé mañana o probá una de estas opciones:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Ver anuncio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // v1: llama directo al provider. Phase 3.3 reemplaza
                  // con AdService real.
                  await context.read<MonetizationProvider>().watchAdForGame(game);
                  if (context.mounted) {
                    Navigator.pop(context, PlayLimitResult.watchedAd);
                  }
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('VER ANUNCIO — +1 JUGADA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Obtener Premium
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaywallScreen(),
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context, PlayLimitResult.upgrade);
                  }
                },
                icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                label: const Text(
                  'OBTENER PREMIUM — \$4.99',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amber, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancelar
            TextButton(
              onPressed: () {
                Navigator.pop(context, PlayLimitResult.dismissed);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
