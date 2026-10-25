import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/pirowflo_result.dart';
import 'package:pirowflo_control/services/pirowflo_result_parser.dart';

void main() {
  group('PiRowFloResultParser', () {
    test('returns null when no result block exists', () {
      const description = '''
Rudertraining

[PIROWFLO]
warmup=7m
work=20m,120-130w
cooldown=5m
[/PIROWFLO]
''';

      final result = PiRowFloResultParser.parse(description);

      expect(result, isNull);
    });

    test('parses valid result block', () {
      const description = '''
[PIROWFLO_RESULT]
endurain_activity_id=1053
linked_at=2026-10-24T21:30:00+02:00
[/PIROWFLO_RESULT]
''';

      final result = PiRowFloResultParser.parse(description);

      expect(result, isNotNull);
      expect(result!.endurainActivityId, 1053);
      expect(result.linkedAt, DateTime.parse('2026-10-24T21:30:00+02:00'));
    });

    test('upsert appends result block to workout description', () {
      const description = '''
Rudertraining

[PIROWFLO]
warmup=7m
repeat=5
work=3m,135-145w
recovery=2m,90-100w
cooldown=5m
[/PIROWFLO]
''';

      final result = PiRowFloResult(
        endurainActivityId: 1053,
        linkedAt: DateTime.parse('2026-10-24T21:30:00+02:00'),
      );

      final updated = PiRowFloResultParser.upsert(description, result);

      expect(updated, contains('[PIROWFLO]'));
      expect(updated, contains('work=3m,135-145w'));
      expect(updated, contains('[PIROWFLO_RESULT]'));
      expect(updated, contains('endurain_activity_id=1053'));
    });

    test('upsert replaces existing result block', () {
      const description = '''
[PIROWFLO]
work=30m,120-130w
[/PIROWFLO]

[PIROWFLO_RESULT]
endurain_activity_id=1053
linked_at=2026-10-24T21:30:00+02:00
[/PIROWFLO_RESULT]
''';

      final result = PiRowFloResult(
        endurainActivityId: 1060,
        linkedAt: DateTime.parse('2026-10-24T22:00:00+02:00'),
      );

      final updated = PiRowFloResultParser.upsert(description, result);

      expect(updated, contains('endurain_activity_id=1060'));
      expect(updated, isNot(contains('endurain_activity_id=1053')));

      expect(RegExp(r'\[PIROWFLO_RESULT\]').allMatches(updated).length, 1);

      expect(updated, contains('work=30m,120-130w'));
    });

    test('upsert preserves surrounding description text', () {
      const description = '''
Mein geplantes Training.

[PIROWFLO]
warmup=5m
work=20m,120-130w
cooldown=5m
[/PIROWFLO]

Bitte locker ausrudern.
''';

      final result = PiRowFloResult(
        endurainActivityId: 1053,
        linkedAt: DateTime.parse('2026-10-24T21:30:00+02:00'),
      );

      final updated = PiRowFloResultParser.upsert(description, result);

      expect(updated, contains('Mein geplantes Training.'));
      expect(updated, contains('Bitte locker ausrudern.'));
      expect(updated, contains('[PIROWFLO]'));
      expect(updated, contains('[PIROWFLO_RESULT]'));
    });
  });
}
