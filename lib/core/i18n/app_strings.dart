/// Strings de la app — base de i18n (Phase 3.4).
///
/// Infraestructura mínima: clase central con las cadenas nuevas de las fases
/// de monetización (3.4/3.5), en español por defecto. El refactor masivo de
/// los strings legacy del resto de la app queda fuera de scope (deferido);
/// a medida que se tocan pantallas, los strings nuevos entran acá.
///
/// `flutter_localizations` + `locale: es` en MaterialApp resuelven la
/// localización de widgets del framework (date pickers, diálogos, etc.).
class AppStrings {
  AppStrings._();

  // ── Paywall (Phase 3.4) ──────────────────────────────────────────────
  static const paywallTitle = 'Pareja Premium';
  static const paywallSubtitle = 'Pago único. Sin suscripciones.';
  static const paywallBuy = 'COMPRAR — \$4.99';
  static const paywallRestore = 'Restaurar compras';
  static const paywallPremiumActive = '✓ Premium activado';
  static const paywallClose = 'CERRAR';
  static const paywallSecureNote = 'Pago seguro via Google Play / App Store.';
  static const paywallPurchaseSuccess = '¡Bienvenido a Pareja Premium!';
  static const paywallPurchaseCancelled = 'Compra cancelada.';
  static const paywallPurchaseFailed =
      'No se pudo completar la compra. Inténtalo de nuevo.';
  static const paywallPurchaseUnavailable =
      'Las compras no están disponibles en este device.';
  static const paywallRestoreSuccess =
      'Compras restauradas. ¡Bienvenido de nuevo!';
  static const paywallRestoreNone = 'No se encontraron compras previas.';
  static const paywallBenefitNoLimit = 'Sin límites de jugadas';
  static const paywallBenefitNoAds = 'Sin anuncios';
  static const paywallBenefitHot18 = 'Modo +18 desbloqueado';
  static const paywallBenefitAllContent = 'Acceso a TODO el contenido';

  // ── Hot mode gate (Phase 3.5) ────────────────────────────────────────
  static const hotModeFree = 'Modo Hot (+18) — Requiere Premium';
  static const hotModePremiumHint =
      'Modo Hot bloqueado. Actívalo en Configuración.';
  static const hotModeGetPremium = 'Obtener Premium';
  static const adultContentTitle = 'Modo adulto (+18)';
  static const adultContentTitleBase = 'Modo adulto';
  static const adultContentLockedDesc =
      'Requiere Premium — obtén acceso al contenido +18';
  static const adultContentActive = 'Activo: contenido +18 habilitado';
  static const adultContentVerifiedHint = 'Verificado: toca para activar';
  static const adultContentVerifyRequired = 'Verificación de edad requerida';
  static const rouletteDareLockedHint = 'Actívalo en Configuración.';
}
