import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/api_workout.dart';
import '../models/scheduled_workout.dart';

class WorkoutCacheData {
  final DateTime cachedAt;
  final List<ScheduledWorkout> workouts;

  const WorkoutCacheData({required this.cachedAt, required this.workouts});
}

class WorkoutCacheService {
  static const _fileName = 'workout_cache.json';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();

    return File('${directory.path}/$_fileName');
  }

  Future<void> save({required List<Map<String, dynamic>> workouts}) async {
    final file = await _file();

    await file.writeAsString(
      jsonEncode({
        'cached_at': DateTime.now().toIso8601String(),
        'workouts': workouts,
      }),
      flush: true,
    );
  }

  Future<WorkoutCacheData?> load() async {
    try {
      final file = await _file();

      if (!await file.exists()) {
        return null;
      }

      final decoded = jsonDecode(await file.readAsString());

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final cachedAt = DateTime.tryParse(
        decoded['cached_at']?.toString() ?? '',
      );

      if (cachedAt == null) {
        return null;
      }

      final rows = decoded['workouts'] as List<dynamic>? ?? const [];

      final workouts = <ScheduledWorkout>[];

      for (final row in rows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }

        final scheduled = ApiWorkout.fromJson(row).toScheduledWorkout();

        if (scheduled != null) {
          workouts.add(scheduled);
        }
      }

      workouts.sort((a, b) => a.start.compareTo(b.start));

      return WorkoutCacheData(cachedAt: cachedAt, workouts: workouts);
    } catch (_) {
      return null;
    }
  }
}
