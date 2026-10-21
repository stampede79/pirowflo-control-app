import 'package:flutter/material.dart';

import '../models/workout.dart';

class WorkoutTimeline extends StatelessWidget {
  final Workout workout;

  const WorkoutTimeline({super.key, required this.workout});

  String _formatDuration(Duration duration) {
    if (duration.inSeconds.remainder(60) == 0) {
      return '${duration.inMinutes} Min.';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')} Min.';
  }

  String _stepDescription(WorkoutStep step) {
    final parts = <String>[_formatDuration(step.duration)];

    if (step.targetPowerMin != null && step.targetPowerMax != null) {
      parts.add('${step.targetPowerMin}–${step.targetPowerMax} W');
    }

    if (step.targetSpmMin != null && step.targetSpmMax != null) {
      parts.add('${step.targetSpmMin}–${step.targetSpmMax} SPM');
    }

    if (step.hasTargetPace) {
      parts.add(
        '${_formatPace(step.targetPaceMinSeconds!)}–'
        '${_formatPace(step.targetPaceMaxSeconds!)} /500 m',
      );
    }

    return parts.join(' · ');
  }

  String _formatPace(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;

    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  bool _sameTargets(WorkoutStep a, WorkoutStep b) {
    return a.duration == b.duration &&
        a.targetPowerMin == b.targetPowerMin &&
        a.targetPowerMax == b.targetPowerMax &&
        a.targetSpmMin == b.targetSpmMin &&
        a.targetSpmMax == b.targetSpmMax &&
        a.targetPaceMinSeconds == b.targetPaceMinSeconds &&
        a.targetPaceMaxSeconds == b.targetPaceMaxSeconds;
  }

  ({WorkoutStep work, WorkoutStep recovery, int count})? _repeatedIntervals() {
    final intervalSteps = workout.steps
        .where(
          (step) =>
              step.type == WorkoutStepType.work ||
              step.type == WorkoutStepType.recovery,
        )
        .toList();

    if (intervalSteps.length < 4 || intervalSteps.length.isOdd) {
      return null;
    }

    final work = intervalSteps.first;
    final recovery = intervalSteps[1];

    if (work.type != WorkoutStepType.work ||
        recovery.type != WorkoutStepType.recovery) {
      return null;
    }

    for (var i = 0; i < intervalSteps.length; i += 2) {
      if (intervalSteps[i].type != WorkoutStepType.work ||
          intervalSteps[i + 1].type != WorkoutStepType.recovery ||
          !_sameTargets(intervalSteps[i], work) ||
          !_sameTargets(intervalSteps[i + 1], recovery)) {
        return null;
      }
    }

    return (work: work, recovery: recovery, count: intervalSteps.length ~/ 2);
  }

  @override
  Widget build(BuildContext context) {
    final repeated = _repeatedIntervals();

    final items = <Widget>[];

    for (final step in workout.steps) {
      if (repeated != null &&
          (step.type == WorkoutStepType.work ||
              step.type == WorkoutStepType.recovery)) {
        if (identical(step, repeated.work)) {
          items.add(
            _TimelineItem(
              icon: Icons.repeat,
              title: 'Intervalle × ${repeated.count}',
              lines: [
                'Belastung: ${_stepDescription(repeated.work)}',
                'Erholung: ${_stepDescription(repeated.recovery)}',
              ],
            ),
          );
        }

        continue;
      }

      items.add(
        _TimelineItem(
          icon: switch (step.type) {
            WorkoutStepType.warmup => Icons.wb_sunny_outlined,
            WorkoutStepType.work => Icons.bolt,
            WorkoutStepType.recovery => Icons.favorite_border,
            WorkoutStepType.cooldown => Icons.water_drop_outlined,
          },
          title: step.title,
          lines: [_stepDescription(step)],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineEntry(showLine: i < items.length - 1, child: items[i]),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final Widget child;
  final bool showLine;

  const _TimelineEntry({required this.child, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
