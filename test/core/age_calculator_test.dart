import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/utils/age_calculator.dart';

void main() {
  group('isAdult', () {
    test('person born 20 years ago is adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2006, 1, 1);
      expect(isAdult(dob, now: now), isTrue);
    });

    test('person born exactly 18 years ago today is adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2008, 7, 25);
      expect(isAdult(dob, now: now), isTrue);
    });

    test('person born 17 years and 364 days ago is NOT adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2008, 7, 26);
      expect(isAdult(dob, now: now), isFalse);
    });

    test('person born 18 years ago, birthday tomorrow, is NOT adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2008, 7, 26);
      expect(isAdult(dob, now: now), isFalse);
    });

    test('person born today is NOT adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2026, 7, 25);
      expect(isAdult(dob, now: now), isFalse);
    });

    test('person born 18 years ago, earlier in the year, is adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2008, 1, 1);
      expect(isAdult(dob, now: now), isTrue);
    });

    test('person born 18 years ago but later in the year is NOT adult', () {
      final now = DateTime(2026, 7, 25);
      final dob = DateTime(2008, 12, 31);
      expect(isAdult(dob, now: now), isFalse);
    });

    test('uses DateTime.now() when no now is provided', () {
      // Born in 1990 → always adult in 2026
      final dob = DateTime(1990, 5, 10);
      expect(isAdult(dob), isTrue);
    });
  });
}
