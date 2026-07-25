import 'package:flutter/material.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/game_button.dart';

/// Pantalla de paywall — stub en Phase 3.2.
///
/// **Phase 3.2 (stub)**: muestra beneficios + boton "Cerrar". El boton
/// "Comprar" no hace nada todavia (Phase 3.4 conecta BillingService).
///
/// **Phase 3.4 (real)**: boton "Comprar \$4.99" llama a BillingService.purchase,
/// restore button, manejo de errores de Play Billing, verificacion de
/// receipts.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pareja Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pago único. Sin suscripciones.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 32),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Benefit(
                          icon: Icons.all_inclusive,
                          text: 'Sin límites de jugadas',
                        ),
                        SizedBox(height: 14),
                        _Benefit(
                          icon: Icons.block,
                          text: 'Sin anuncios',
                        ),
                        SizedBox(height: 14),
                        _Benefit(
                          icon: Icons.local_fire_department,
                          text: 'Modo +18 desbloqueado',
                        ),
                        SizedBox(height: 14),
                        _Benefit(
                          icon: Icons.lock_open,
                          text: 'Acceso a TODO el contenido',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Stub: boton "Comprar" wired pero no-op hasta Phase 3.4.
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    text: 'PRÓXIMAMENTE — \$4.99',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Las compras in-app estarán disponibles pronto.',
                          ),
                        ),
                      );
                    },
                    style: GameButtonStyle.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Restaurar compras — disponible en v1.1'),
                      ),
                    );
                  },
                  child: const Text(
                    'Restaurar compras',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Próximamente — Phase 3.4',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
