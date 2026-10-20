import '../models/workout.dart';

class WorkoutParser {
  static Workout? parse({required String name, required String description}) {
    final match = RegExp(
      r'\[PIROWFLO\](.*?)\[/PIROWFLO\]',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(description);

    if (match == null) {
      return null;
    }

    final block = match.group(1)!;
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

    final steps = <WorkoutStep>[];

    final warmup = values['warmup'];
    if (warmup != null) {
      steps.add(
        WorkoutStep(
          type: WorkoutStepType.warmup,
          title: 'Einrudern',
          duration: _parseDuration(warmup),
        ),
      );
    }

    final repeat = int.tryParse(values['repeat'] ?? '') ?? 1;
    final work = values['work'];
    final recovery = values['recovery'];

    if (work != null) {
      for (var i = 1; i <= repeat; i++) {
        steps.add(
          _parseStep(
            work,
            type: WorkoutStepType.work,
            title: repeat > 1 ? 'Intervall $i / $repeat' : 'Hauptteil',
          ),
        );

        if (recovery != null) {
          steps.add(
            _parseStep(
              recovery,
              type: WorkoutStepType.recovery,
              title: 'Erholung $i / $repeat',
            ),
          );
        }
      }
    }

    final cooldown = values['cooldown'];
    if (cooldown != null) {
      steps.add(
        WorkoutStep(
          type: WorkoutStepType.cooldown,
          title: 'Ausrudern',
          duration: _parseDuration(cooldown),
        ),
      );
    }

    if (steps.isEmpty) {
      return null;
    }

    return Workout(
      name: name,
      description: _humanDescription(values),
      steps: steps,
    );
  }

  static WorkoutStep _parseStep(
    String definition, {
    required WorkoutStepType type,
    required String title,
  }) {
    final parts = definition
        .split(',')
        .map((part) => part.trim().toLowerCase())
        .toList();

    final duration = _parseDuration(parts.first);

    int? powerMin;
    int? powerMax;
    int? spmMin;
    int? spmMax;

    for (final part in parts.skip(1)) {
      if (part.endsWith('w')) {
        final range = _parseRange(part.substring(0, part.length - 1));
        powerMin = range.$1;
        powerMax = range.$2;
      }

      if (part.endsWith('spm')) {
        final range = _parseRange(part.substring(0, part.length - 3));
        spmMin = range.$1;
        spmMax = range.$2;
      }
    }

    return WorkoutStep(
      type: type,
      title: title,
      duration: duration,
      targetPowerMin: powerMin,
      targetPowerMax: powerMax,
      targetSpmMin: spmMin,
      targetSpmMax: spmMax,
    );
  }

  static Duration _parseDuration(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.endsWith('m')) {
      final minutes = int.parse(normalized.substring(0, normalized.length - 1));

      return Duration(minutes: minutes);
    }

    if (normalized.endsWith('s')) {
      final seconds = int.parse(normalized.substring(0, normalized.length - 1));

      return Duration(seconds: seconds);
    }

    throw FormatException('Ungültige Dauer: $value');
  }

  static (int, int) _parseRange(String value) {
    final parts = value.split('-');

    if (parts.length == 1) {
      final number = int.parse(parts.first.trim());
      return (number, number);
    }

    if (parts.length != 2) {
      throw FormatException('Ungültiger Zielbereich: $value');
    }

    return (int.parse(parts[0].trim()), int.parse(parts[1].trim()));
  }

  static String _humanDescription(Map<String, String> values) {
    final repeat = int.tryParse(values['repeat'] ?? '') ?? 1;
    final work = values['work'];
    final recovery = values['recovery'];

    if (repeat > 1 && work != null) {
      final workDuration = work.split(',').first.trim();

      if (recovery != null) {
        final recoveryDuration = recovery.split(',').first.trim();
        return '$repeat × $workDuration Belastung / '
            '$recoveryDuration locker';
      }

      return '$repeat × $workDuration Belastung';
    }

    return 'Geplantes Rudertraining';
  }
}
