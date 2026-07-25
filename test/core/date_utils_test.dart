import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/utils/date_utils.dart';

void main() {
  group('DateUtils.dayKey', () {
    test('formato YYYY-MM-DD con padding', () {
      expect(DateUtils.dayKey(DateTime(2026, 7, 25)), '2026-07-25');
      expect(DateUtils.dayKey(DateTime(2026, 1, 1)), '2026-01-01');
      expect(DateUtils.dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('mes y dia se paddean a 2 digitos', () {
      expect(DateUtils.dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('DateUtils.isSameDay', () {
    test('mismo dia retorna true', () {
      final a = DateTime(2026, 7, 25, 9, 0);
      final b = DateTime(2026, 7, 25, 23, 59);
      expect(DateUtils.isSameDay(a, b), true);
    });

    test('distinto dia retorna false', () {
      final a = DateTime(2026, 7, 25, 23, 59);
      final b = DateTime(2026, 7, 26, 0, 1);
      expect(DateUtils.isSameDay(a, b), false);
    });

    test('distinto mes retorna false', () {
      expect(
        DateUtils.isSameDay(DateTime(2026, 7, 25), DateTime(2026, 8, 25)),
        false,
      );
    });

    test('distinto anio retorna false', () {
      expect(
        DateUtils.isSameDay(DateTime(2026, 1, 1), DateTime(2027, 1, 1)),
        false,
      );
    });
  });

  group('DateUtils.isDayRollover', () {
    test('stored null retorna true (primer arranque)', () {
      expect(DateUtils.isDayRollover(null, DateTime(2026, 7, 25)), true);
    });

    test('mismo dia retorna false', () {
      final stored = DateTime(2026, 7, 25, 0, 1);
      final now = DateTime(2026, 7, 25, 23, 59);
      expect(DateUtils.isDayRollover(stored, now), false);
    });

    test('dia siguiente retorna true (medianoche paso)', () {
      final stored = DateTime(2026, 7, 25, 23, 59);
      final now = DateTime(2026, 7, 26, 0, 0);
      expect(DateUtils.isDayRollover(stored, now), true);
    });

    test('mes siguiente retorna true', () {
      final stored = DateTime(2026, 7, 31, 23, 0);
      final now = DateTime(2026, 8, 1, 1, 0);
      expect(DateUtils.isDayRollover(stored, now), true);
    });
  });
}
