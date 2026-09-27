import 'package:pareja/services/billing_service.dart';

/// Fake determinista para tests del flujo de compra/restore.
///
/// El outcome de [purchasePremium] se configura con [defaultOutcome]
/// (por defecto success, cancelable por llamada via [outcomes]).
class FakeBillingService extends BillingService {
  FakeBillingService({
    this.defaultOutcome = PurchaseOutcome.success,
    this.restoreResult = true,
    this.available = true,
    List<PurchaseOutcome>? outcomes,
  }) : outcomes = outcomes ?? <PurchaseOutcome>[];

  /// Cola de outcomes por llamada; si se vacía, usa [defaultOutcome].
  final List<PurchaseOutcome> outcomes;
  final PurchaseOutcome defaultOutcome;
  final bool restoreResult;
  final bool available;

  bool _ready = false;
  bool _hasPremium = false;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  bool get isReady => _ready;

  @override
  bool get hasPremium => _hasPremium;

  @override
  Future<void> init() async {
    _ready = available;
  }
@override
  Future<PurchaseOutcome> purchasePremium() async {
    purchaseCalls++;
    if (!_ready) return PurchaseOutcome.unavailable;
    final outcome =
        outcomes.isNotEmpty ? outcomes.removeAt(0) : defaultOutcome;
    if (outcome == PurchaseOutcome.success) _hasPremium = true;
    return outcome;
  }

  @override
  Future<bool> restorePurchases() async {
    restoreCalls++;
    if (restoreResult) _hasPremium = true;
    return restoreResult;
  }
}
