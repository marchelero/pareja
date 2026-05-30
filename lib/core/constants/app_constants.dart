class AppConstants {
  AppConstants._();

  static const String appName = 'LOVEPLAY';
  static const String appVersion = '1.0.0';

  static const String defaultHeName = 'ÉL';
  static const String defaultSheName = 'ELLA';

  static const String assetSounds = 'assets/sounds/';
  static const String assetImages = 'assets/images/';

  static const String soundClick = 'clic.mp3';
  static const String soundLevelUp = 'level_up.mp3';
  static const String soundGameOver = 'game_over.mp3';
  static const String soundDrink = 'drink.mp3';

  static const int rouletteMaxSpinsForHot = 8;
  static const int maxIconsNeonBackground = 10;
  static const int neonAnimationDurationSeconds = 15;

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  static const double glassBorderRadius = 25.0;
  static const double glassBlurSigma = 10.0;
}
