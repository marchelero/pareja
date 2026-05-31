import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pareja/app.dart';
import 'package:pareja/screens/home_screen.dart';
import 'package:pareja/providers/settings_provider.dart';
import 'package:pareja/services/audio_service.dart';

void main() {
  testWidgets('App renders HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AudioService()),
        ],
        child: const App(home: HomeScreen()),
      ),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
