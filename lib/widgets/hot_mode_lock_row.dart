import 'package:flutter/material.dart';
import '../core/i18n/app_strings.dart';
import '../screens/paywall/paywall_screen.dart';

/// Fila de bloqueo del Modo Hot (+18) usada en los start screens.
///
/// Dos estados:
///  - **Free user** (`isPremium == false`): mensaje "Requiere Premium" +
///    CTA que navega a [PaywallScreen]. El hot mode es premium-only.
///  - **Premium user sin hot mode activo**: hint de que debe activarlo en
///    Configuración (el toggle real aparece si `hotModeEnabled`).
class HotModeLockRow extends StatelessWidget {
  const HotModeLockRow({super.key, required this.isPremium});

  final bool isPremium;

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCta = !isPremium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              showCta ? AppStrings.hotModeFree : AppStrings.hotModePremiumHint,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          if (showCta)
            TextButton(
              onPressed: () => _openPaywall(context),
              child: const Text(
                AppStrings.hotModeGetPremium,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
