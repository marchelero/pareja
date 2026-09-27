import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Resultado de [BillingService.purchasePremium].
enum PurchaseOutcome { success, cancelled, failed, unavailable }

/// Wrapper sobre `in_app_purchase` (Play Billing / StoreKit).
///
/// **Por qué existe**: aislar el plugin para que [PaywallScreen] y
/// [MonetizationProvider] no dependan de detalles de plataforma, y poder
/// inyectar un fake en tests (el plugin no corre en el test binding).
///
/// Flujo:
///  - [init]: verifica disponibilidad del store y los detalles del producto
///    premium (non-consumible `pareja_premium`).
///  - [purchasePremium]: lanaza la compra y espera el stream de
///    [InAppPurchase] para resolver el outcome.
///  - [restorePurchases]: re-emite compras previas de la plataforma.
///
/// La **fuente de verdad** del estado premium sigue siendo `LocalStorage`
/// (via MonetizationProvider): acá solo se reportan eventos de billing.
abstract class BillingService {
  /// Product ID del premium (non-consumible). Debe existir en Play Console /
  /// App Store Connect con el mismo id.
  static const String premiumProductId = 'pareja_premium';

  /// True cuando [init] terminó y el store está disponible.
  bool get isReady;

  /// True si el stream reportó una compra no consumible vigente del premium.
  bool get hasPremium;

  /// Verifica disponibilidad + producto. Idempotente. No lanzar.
  Future<void> init();

  /// Flujo completo de compra del premium. Resuelve cuando la plataforma
  /// confirmó (o el user canceló / falló / no disponible).
  Future<PurchaseOutcome> purchasePremium();

  /// Restaura compras previas. True si el premium quedó activo.
  Future<bool> restorePurchases();
}

/// Implementación real contra Play Billing / StoreKit.
///
/// En entornos sin store (web, tests, emulador sin Play) [init] deja
/// `isReady == false` y [purchasePremium] retorna [PurchaseOutcome.unavailable].
class PlayBillingService extends BillingService {
  /// Inyectable para tests del flujo de stream.
  final InAppPurchase _iap;

  ProductDetails? _premiumProduct;
  bool _ready = false;
  bool _hasPremium = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PurchaseOutcome>? _pending;

  PlayBillingService({InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  @override
  bool get isReady => _ready;

  @override
  bool get hasPremium => _hasPremium;

  @override
  Future<void> init() async {
    _sub ??= _iap.purchaseStream.listen(_onPurchases);
    if (_ready) return;
    final available = await _iap.isAvailable();
    if (!available) return;
    final details = await _iap.queryProductDetails({
      BillingService.premiumProductId,
    });
    if (details.productDetails.isNotEmpty) {
      _premiumProduct = details.productDetails.firstWhere(
        (p) => p.id == BillingService.premiumProductId,
        orElse: () => details.productDetails.first,
      );
    }
    if (_premiumProduct != null) _ready = true;
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != BillingService.premiumProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _hasPremium = true;
          _iap.completePurchase(purchase);
          _pending?.complete(PurchaseOutcome.success);
        case PurchaseStatus.canceled:
          _pending?.complete(PurchaseOutcome.cancelled);
        case PurchaseStatus.error:
        case PurchaseStatus.pending:
          _pending?.complete(PurchaseOutcome.failed);
      }
      _pending = null;
    }
  }

  @override
  Future<PurchaseOutcome> purchasePremium() async {
    if (!_ready || _premiumProduct == null) return PurchaseOutcome.unavailable;
    if (_pending != null) return PurchaseOutcome.failed; // compra en vuelo
    final completer = Completer<PurchaseOutcome>();
    _pending = completer;
    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _premiumProduct!),
    );
    if (!started) {
      _pending = null;
      return PurchaseOutcome.failed;
    }
    // Timeout de seguridad si la plataforma no emite al stream.
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending = null;
        return PurchaseOutcome.failed;
      },
    );
  }

  @override
  Future<bool> restorePurchases() async {
    if (!_ready) return _hasPremium;
    try {
      await _iap.restorePurchases();
    } catch (_) {
      // Restore sin store / fallo de plataforma: reportamos lo conocido.
    }
    return _hasPremium;
  }

  /// Cancelar el listener. No necesario en uso app-lifetime.
  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
