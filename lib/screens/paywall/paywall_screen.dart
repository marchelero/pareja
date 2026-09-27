import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/monetization_provider.dart';
import '../../services/billing_service.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/game_button.dart';

/// Pantalla de paywall — Phase 3.4 (IAP real).
///
/// Muestra beneficios del premium y el flujo de compra via
/// [MonetizationProvider.purchasePremium] (BillingService). Incluye
/// restaurar compras, estados de loading y manejo de errores/cancelación.
///
/// Requiere `MonetizationProvider` en el árbol (provisto globalmente en
/// main.dart). Si ya es premium, muestra estado "activado" con CTA de cierre.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _busy = false;

  Future<void> _purchase() async {
    final monetization = context.read<MonetizationProvider>();
    setState(() => _busy = true);
    final outcome = await monetization.purchasePremium();
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case PurchaseOutcome.success:
        messenger.showSnackBar(
          const SnackBar(content: Text('¡Bienvenido a Pareja Premium!')),
        );
      case PurchaseOutcome.cancelled:
        messenger.showSnackBar(
          const SnackBar(content: Text('Compra cancelada.')),
        );
      case PurchaseOutcome.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo completar la compra. Inténtalo de nuevo.',
            ),
          ),
        );
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Las compras no están disponibles en este device.'),
          ),
        );
    }
  }

  Future<void> _restore() async {
    final monetization = context.read<MonetizationProvider>();
    setState(() => _busy = true);
    final restored = await monetization.restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Compras restauradas. ¡Bienvenido de nuevo!'
              : 'No se encontraron compras previas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<MonetizationProvider>().isPremium;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 32),
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
                          _Benefit(icon: Icons.block, text: 'Sin anuncios'),
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
                  if (isPremium)
                    Column(
                      children: [
                        const Text(
                          '✓ Premium activado',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GameButton(
                            text: 'CERRAR',
                            onPressed: () => Navigator.pop(context),
                            style: GameButtonStyle.secondary,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ),
                              ),
                            )
                          : GameButton(
                              text: 'COMPRAR — \$4.99',
                              onPressed: _purchase,
                              style: GameButtonStyle.primary,
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: const Text(
                        'Restaurar compras',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pago seguro via Google Play / App Store.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ],
              ),
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
