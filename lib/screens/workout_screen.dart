import 'dart:async';

import 'package:flutter/material.dart';

import '../models/workout.dart';

import '../models/rowing_metrics.dart';
import '../services/metrics_service.dart';

class WorkoutScreen extends StatefulWidget {
  final Workout workout;
  final String server;
  final String apiKey;

  const WorkoutScreen({
    super.key,
    required this.workout,
    required this.server,
    required this.apiKey,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? timer;
  Timer? metricsTimer;
  RowingMetrics? metrics;
  String? metricsError;

  int currentStepIndex = 0;
  late Duration remaining;

  bool running = false;
  bool finished = false;

  WorkoutStep get currentStep => widget.workout.steps[currentStepIndex];

  @override
  void initState() {
    super.initState();
    remaining = currentStep.duration;
    loadMetrics();

    metricsTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => loadMetrics(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
    metricsTimer?.cancel();
  }

  void start() {
    if (finished) return;

    setState(() {
      running = true;
    });

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void pause() {
    timer?.cancel();

    setState(() {
      running = false;
    });
  }

  void tick() {
    if (!mounted || !running) return;

    if (remaining.inSeconds > 1) {
      setState(() {
        remaining -= const Duration(seconds: 1);
      });
      return;
    }

    nextStep();
  }

  void nextStep() {
    timer?.cancel();

    if (currentStepIndex >= widget.workout.steps.length - 1) {
      setState(() {
        remaining = Duration.zero;
        running = false;
        finished = true;
      });

      return;
    }

    setState(() {
      currentStepIndex++;
      remaining = currentStep.duration;
    });

    if (running) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<void> loadMetrics() async {
    try {
      final service = MetricsService(
        server: widget.server,
        apiKey: widget.apiKey,
      );

      final result = await service.getMetrics();

      if (!mounted) return;

      setState(() {
        metrics = result;
        metricsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        metricsError = 'Keine Live-Daten';
      });
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String livePace(int seconds) {
    if (seconds <= 0) {
      return '--:--';
    }

    return formatPace(seconds);
  }

  String powerStatus(WorkoutStep step, RowingMetrics metrics) {
    if (step.targetPowerMin == null || step.targetPowerMax == null) {
      return '';
    }

    if (!metrics.rowing || metrics.powerW == 0) {
      return 'BEREIT';
    }

    if (metrics.powerW < step.targetPowerMin!) {
      return 'LEISTUNG ERHÖHEN';
    }

    if (metrics.powerW > step.targetPowerMax!) {
      return 'ETWAS REDUZIEREN';
    }

    return 'IM ZIELBEREICH';
  }

  String formatPace(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;

    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  String stepTypeLabel(WorkoutStepType type) {
    return switch (type) {
      WorkoutStepType.warmup => 'WARM-UP',
      WorkoutStepType.work => 'BELASTUNG',
      WorkoutStepType.recovery => 'ERHOLUNG',
      WorkoutStepType.cooldown => 'COOL-DOWN',
    };
  }

  @override
  Widget build(BuildContext context) {
    final step = currentStep;

    final progress = step.duration.inSeconds == 0
        ? 0.0
        : 1 - (remaining.inSeconds / step.duration.inSeconds);

    final upcomingStep = currentStepIndex < widget.workout.steps.length - 1
        ? widget.workout.steps[currentStepIndex + 1]
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                stepTypeLabel(step.type),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Text(
                finished ? 'FERTIG' : formatDuration(remaining),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: finished ? 1 : progress.clamp(0.0, 1.0),
                minHeight: 12,
              ),
              const SizedBox(height: 32),
              if (metrics != null) ...[
                Text(
                  '${metrics!.powerW} W',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),

                if (step.targetPowerMin != null &&
                    step.targetPowerMax != null) ...[
                  const SizedBox(height: 4),

                  Text(
                    powerStatus(step, metrics!),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Ziel: ${step.targetPowerMin}–${step.targetPowerMax} W',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          metrics!.strokeRateSpm.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('SPM'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          livePace(metrics!.pace500mSeconds),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('/500 m'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${metrics!.distanceM}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('Meter'),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                const Center(child: CircularProgressIndicator()),
              ],
              if (metricsError != null) ...[
                const SizedBox(height: 12),
                Text(
                  metricsError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (step.hasTargetPace)
                Text(
                  'Zielpace: '
                  '${formatPace(step.targetPaceMinSeconds!)}–'
                  '${formatPace(step.targetPaceMaxSeconds!)} /500 m',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (step.targetSpmMin != null && step.targetSpmMax != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Schlagrate: '
                  '${step.targetSpmMin}–${step.targetSpmMax} SPM',
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (upcomingStep != null && !finished)
                Text(
                  'Danach: ${upcomingStep.title} '
                  '(${formatDuration(upcomingStep.duration)})',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              if (!finished)
                FilledButton.icon(
                  onPressed: running ? pause : start,
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(running ? 'Pause' : 'Start / Fortsetzen'),
                ),
              const SizedBox(height: 12),
              if (!finished)
                OutlinedButton.icon(
                  onPressed: nextStep,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Abschnitt überspringen'),
                ),
              if (finished)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Training beenden'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
