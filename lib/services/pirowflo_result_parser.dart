import '../models/pirowflo_result.dart';

class PiRowFloResultParser {
  static final RegExp _blockPattern = RegExp(
    r'\[PIROWFLO_RESULT\](.*?)\[/PIROWFLO_RESULT\]',
    caseSensitive: false,
    dotAll: true,
  );

  static PiRowFloResult? parse(String description) {
    final match = _blockPattern.firstMatch(description);

    if (match == null) {
      return null;
    }

    final values = _parseValues(match.group(1)!);

    final activityId = int.tryParse(values['endurain_activity_id'] ?? '');

    final linkedAt = DateTime.tryParse(values['linked_at'] ?? '');

    if (activityId == null || linkedAt == null) {
      return null;
    }

    return PiRowFloResult(endurainActivityId: activityId, linkedAt: linkedAt);
  }

  static String upsert(String description, PiRowFloResult result) {
    final block = _buildBlock(result);

    if (_blockPattern.hasMatch(description)) {
      return description.replaceFirst(_blockPattern, block);
    }

    final trimmed = description.trimRight();

    if (trimmed.isEmpty) {
      return block;
    }

    return '$trimmed\n\n$block';
  }

  static Map<String, String> _parseValues(String block) {
    final values = <String, String>{};

    for (final rawLine in block.split('\n')) {
      final line = rawLine.trim();

      if (line.isEmpty || !line.contains('=')) {
        continue;
      }

      final separator = line.indexOf('=');
      final key = line.substring(0, separator).trim().toLowerCase();

      final value = line.substring(separator + 1).trim();

      values[key] = value;
    }

    return values;
  }

  static String _buildBlock(PiRowFloResult result) {
    return '[PIROWFLO_RESULT]\n'
        'endurain_activity_id=${result.endurainActivityId}\n'
        'linked_at=${result.linkedAt.toIso8601String()}\n'
        '[/PIROWFLO_RESULT]';
  }
}
