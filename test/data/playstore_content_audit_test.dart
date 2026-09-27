// Regression guard for the Play Store editorial audit (commit 4ab7bd4).
//
// Run with: flutter test test/data/playstore_content_audit_test.dart
//
// Why this test exists: the data layer (`assets/data/*.json`) contains hot
// content. Five specific items were flagged in the editorial audit as
// borderline or problematic for Play Store tier +12 (Madurez media). If any
// of those items reappear during future content updates, this test fails.
//
// Scope: data-layer only. It does NOT cover Phase 2 (hot-mode gate) which
// will live in lib/providers/settings_provider.dart and the repositories.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _dataDir = 'assets/data';

const _dataFiles = <String>[
  'bomb_categories.json',
  'charades_words.json',
  'drinks_tasks.json',
  'never_have_i_ever.json',
  'questions.json',
  'rapid_fire_questions.json',
  'roulette_dare.json',
];

// Strings flagged in the audit. None of these may appear in any data file.
// If a new borderline item is added, the audit decision should be revisited
// before adding it to this list.
const _forbiddenStrings = <String>[
  // Phase 1 — strip-tease removal
  'quita una prenda',
  'quítate una prenda',
  'quítale una prenda',
  'te quite una prenda',
  'qué prenda te quitas',
  // Phase 1 — borderline intimacy
  'baile sexy',
  'videollamada íntima',
  // Phase 1 — explicit bedroom talk
  'gimes o dices en la cama',
  // Phase 1 — health policy risk
  'sexo sin protección',
];

void main() {
  late Map<String, String> fileContents;

  setUpAll(() {
    fileContents = <String, String>{
      for (final f in _dataFiles)
        f: File('$_dataDir/$f').readAsStringSync(),
    };
  });

  group('Play Store content audit — blacklist', () {
    test('forbidden strings are not present in any data file', () {
      final violations = <String>[];
      for (final entry in fileContents.entries) {
        for (final banned in _forbiddenStrings) {
          if (entry.value.contains(banned)) {
            violations.add('"${entry.key}" contains forbidden "${banned}"');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Forbidden content re-introduced. Violations:\n'
            '  - ${violations.join('\n  - ')}',
      );
    });
  });

  group('Play Store content audit — structural changes', () {
    test('never_have_i_ever.json id 58 was removed (health policy)', () {
      final items = jsonDecode(fileContents['never_have_i_ever.json']!) as List;
      final hasId58 = items.any((dynamic i) => (i as Map)['id'] == 58);
      expect(hasId58, isFalse, reason: 'id 58 must be deleted; promotes unsafe sex');
    });

    test('never_have_i_ever.json id 54 reformulated', () {
      final items = jsonDecode(fileContents['never_have_i_ever.json']!) as List;
      final id54 = items.firstWhere(
        (dynamic i) => (i as Map)['id'] == 54,
        orElse: () => null,
      );
      expect(id54, isNotNull, reason: 'id 54 missing');
      expect((id54 as Map)['text'], 'hecho una llamada atrevida');
    });

    test('bomb_categories id 10 reformulated', () {
      final items = jsonDecode(fileContents['bomb_categories.json']!) as List;
      final id10 = items.firstWhere(
        (dynamic i) => (i as Map)['id'] == '10',
        orElse: () => null,
      );
      expect(id10, isNotNull, reason: 'id 10 missing');
      expect((id10 as Map)['text'], 'Cosas que te encienden');
    });

    test('roulette_dare.json no "baile sexy"', () {
      expect(fileContents['roulette_dare.json']!, contains('baile sensual'));
      expect(fileContents['roulette_dare.json']!, isNot(contains('baile sexy')));
    });

    test('drinks_tasks hot items are no-strip', () {
      // The 5 audited hot ids (hot7, hot15, hot26, hot42, hot86) must not
      // reference strip-tease. This is the strictest form of the check.
      const hotIds = <String>['hot7', 'hot15', 'hot26', 'hot42', 'hot86'];
      final content = fileContents['drinks_tasks.json']!;
      final violations = <String>[];

      for (final id in hotIds) {
        // Match the "id":"hotN" pair with its "text" field, allowing
        // arbitrary JSON whitespace between them.
        final pattern = RegExp(
          '"id"\\s*:\\s*"' + id + '"[\\s\\S]*?"text"\\s*:\\s*"([^"]+)"',
        );
        final match = pattern.firstMatch(content);
        if (match == null) {
          violations.add('$id: not found');
          continue;
        }
        final text = (match.group(1) ?? '').toLowerCase();
        // Look for the strip-remove verb in any conjugation.
        if (RegExp(r'\b(quita|quítate|quítale|quitar|quitas)\b').hasMatch(text)) {
          violations.add('$id: "$text" still references strip');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Hot items still reference strip:\n  - ${violations.join('\n  - ')}',
      );
    });
  });
}
