import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/constants/game_caps.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/widgets/play_limit_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness({
  required GameCap game,
  required MonetizationProvider provider,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<MonetizationProvider>.value(
      value: provider,
      child: Scaffold(
        body: PlayLimitIndicator(game: game),
      ),
    ),
  );
}

Future<MonetizationProvider> _provider({
  bool premium = false,
  Map<String, int> counts = const {},
}) async {
  SharedPreferences.setMockInitialValues({});
  final p = MonetizationProvider();
  await p.load();
  if (premium) await p.setPremium(true);
  for (final entry in counts.entries) {
    final game = GameCap.fromName(entry.key);
    if (game == null) continue;
    for (int i = 0; i < entry.value; i++) {
      await p.recordPlay(game);
    }
  }
  return p;
}

void main() {
  testWidgets('uncapped game: renderiza vacio (no muestra badge)',
      (tester) async {
    final p = await _provider();
    await tester.pumpWidget(_harness(game: GameCap.yoNunca, provider: p));
    expect(find.text('Sin jugadas restantes hoy'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('capped + premium: renderiza vacio', (tester) async {
    final p = await _provider(premium: true);
    await tester.pumpWidget(_harness(game: GameCap.ruleta, provider: p));
    expect(find.text('3 jugadas restantes'), findsNothing);
    expect(find.text('Sin jugadas restantes hoy'), findsNothing);
  });

  testWidgets('capped + 3 plays usadas: "Sin jugadas restantes" rojo',
      (tester) async {
    final p = await _provider(counts: {'Ruleta': 3});
    await tester.pumpWidget(_harness(game: GameCap.ruleta, provider: p));
    expect(find.text('Sin jugadas restantes hoy'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('capped + 1 play usada: "1 jugada restante" (singular)',
      (tester) async {
    final p = await _provider(counts: {'Ruleta': 2});
    await tester.pumpWidget(_harness(game: GameCap.ruleta, provider: p));
    expect(find.text('1 jugada restante'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
  });

  testWidgets('capped + 0 plays: "3 jugadas restantes" (plural)',
      (tester) async {
    final p = await _provider();
    await tester.pumpWidget(_harness(game: GameCap.ruleta, provider: p));
    expect(find.text('3 jugadas restantes'), findsOneWidget);
  });

  testWidgets('capped + 2 plays: "2 jugadas restantes"', (tester) async {
    final p = await _provider(counts: {'Ruleta': 1});
    await tester.pumpWidget(_harness(game: GameCap.ruleta, provider: p));
    expect(find.text('2 jugadas restantes'), findsOneWidget);
  });
}
