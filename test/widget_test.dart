import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/app.dart';
import 'package:pareja/screens/home_screen.dart';

void main() {
  testWidgets('App renders HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const App(home: HomeScreen()));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
