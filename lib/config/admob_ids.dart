/// IDs de AdMob. Test IDs en debug, real IDs en release via --dart-define.
///
/// Build prod:
///   flutter build apk --release \
///     --dart-define=ADMOB_APP_ID_ANDROID=ca-app-pub-XXXX~YYYY \
///     --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/AAAA \
///     --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/BBBB \
///     --dart-define=ADMOB_APP_ID_IOS=ca-app-pub-XXXX~YYYY \
///     --dart-define=ADMOB_BANNER_IOS=ca-app-pub-XXXX/AAAA \
///     --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXX/BBBB
class AdMobIds {
  AdMobIds._();

  // ── Android ──
  static const String appIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713', // test
  );
  static const String bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // test
  );
  static const String rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // test
  );

  // ── iOS ──
  static const String appIdIos = String.fromEnvironment(
    'ADMOB_APP_ID_IOS',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511', // test
  );
  static const String bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716', // test
  );
  static const String rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // test
  );
}
