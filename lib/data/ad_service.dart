import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import '../config/admob_ids.dart';

/// Capa de abstraccion sobre AdMob. Permite:
/// - Mockear ads en tests (FakeAdService)
/// - NoOp en plataformas no soportadas (web)
/// - Swappear impl real sin cambiar call sites
abstract class AdService {
  /// Inicializa el SDK. Llamar una vez al arranque.
  Future<void> initialize();

  /// Muestra un rewarded video. Retorna true si el user gano la recompensa.
  /// Retorna false si: ad no cargo, user cerro sin completar, o plataforma
  /// no soporta ads.
  Future<bool> showRewardedAd();

  /// Construye un widget banner ad. Retorna SizedBox.shrink() si ads
  /// no estan disponibles (web, error de carga, o premium user).
  Widget buildBannerAd();

  /// True si el servicio puede mostrar ads en este momento.
  bool get isAvailable;

  /// Libera recursos. Llamar en dispose.
  Future<void> dispose();
}

/// No-op implementation. Usado en:
/// - Tests (default en MonetizationProvider)
/// - Web (AdMob no soporta)
/// - Cuando initialize() falla
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewardedAd() async => false;

  @override
  Widget buildBannerAd() => const SizedBox.shrink();

  @override
  bool get isAvailable => false;

  @override
  Future<void> dispose() async {}
}

/// Real AdMob implementation para Android/iOS.
///
/// **Limitaciones**:
/// - Solo 1 rewarded ad pre-loadado a la vez (load on init, reload on complete).
/// - Banner ads se construyen bajo demanda (AdWidget requiere Widget tree).
/// - En web, todos los metodos son no-op.
class MobileAdService implements AdService {
  admob.RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  bool get isAvailable => _isInitialized && !kIsWeb;

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;
    await admob.MobileAds.instance.initialize();
    _isInitialized = true;
    _preloadRewarded();
  }

  void _preloadRewarded() {
    if (!isAvailable || _isLoading) return;
    _isLoading = true;
    final unitId = defaultTargetPlatform == TargetPlatform.iOS
        ? AdMobIds.rewardedIos
        : AdMobIds.rewardedAndroid;
    admob.RewardedAd.load(
      adUnitId: unitId,
      request: const admob.AdRequest(),
      rewardedAdLoadCallback: admob.RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  @override
  Future<bool> showRewardedAd() async {
    if (!isAvailable) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = admob.FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        if (!completer.isCompleted) completer.complete(false);
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        if (!completer.isCompleted) completer.complete(false);
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
      },
    );

    ad.show(
      onUserEarnedReward: (_, _) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  @override
  Widget buildBannerAd() {
    if (!isAvailable) return const SizedBox.shrink();
    final unitId = defaultTargetPlatform == TargetPlatform.iOS
        ? AdMobIds.bannerIos
        : AdMobIds.bannerAndroid;
    final banner = admob.BannerAd(
      adUnitId: unitId,
      size: admob.AdSize.banner,
      request: const admob.AdRequest(),
      listener: admob.BannerAdListener(
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    )..load();
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: admob.AdWidget(ad: banner),
    );
  }

  @override
  Future<void> dispose() async {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isInitialized = false;
  }
}
