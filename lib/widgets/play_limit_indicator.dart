import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/game_caps.dart';
import '../providers/monetization_provider.dart';
import 'glass_card.dart';

/// Badge "X jugadas restantes" que se muestra arriba del boton EMPEZAR
/// en los 5 juegos capped (medianos).
///
/// **Comportamiento**:
/// - Si el juego no es capped: no se muestra (retorna SizedBox.shrink).
/// - Si el user es premium: no se muestra (sin caps).
/// - Si el user jugo el cap completo: muestra "Sin jugadas restantes" en rojo.
/// - Si le quedan plays: muestra "X jugadas restantes" en color neutral.
class PlayLimitIndicator extends StatelessWidget {
  final GameCap game;

  const PlayLimitIndicator({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final monetization = context.watch<MonetizationProvider>();

    // No mostrar para juegos sin cap.
    if (!game.isCapped) return const SizedBox.shrink();

    // No mostrar para premium users.
    if (monetization.isPremium) return const SizedBox.shrink();

    final remaining = monetization.remainingPlays(game);
    final isOut = remaining == 0;
    final color = isOut ? Colors.redAccent : Colors.amberAccent;
    final label = isOut
        ? 'Sin jugadas restantes hoy'
        : '$remaining ${remaining == 1 ? "jugada restante" : "jugadas restantes"}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40, right: 40),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOut ? Icons.lock_outline : Icons.local_fire_department,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
