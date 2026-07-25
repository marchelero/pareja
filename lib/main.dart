import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/ad_service.dart';
import 'services/audio_service.dart';
import 'providers/settings_provider.dart';
import 'providers/monetization_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdService. Si falla o es web, usa NoOp.
  AdService adService;
  try {
    final mobile = MobileAdService();
    await mobile.initialize();
    adService = mobile;
  } catch (e) {
    adService = const NoOpAdService();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AdService>.value(value: adService),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(
          create: (_) => MonetizationProvider(adService: adService),
        ),
      ],
      child: const App(home: SplashScreen()),
    ),
  );
}
