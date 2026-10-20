import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/workout.dart';

import '../models/rowing_metrics.dart';
import '../services/metrics_service.dart';
import '../models/workout_step_result.dart';
import '../services/workout_step_recorder.dart';

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

  final AudioPlayer audioPlayer = AudioPlayer();

  RowingMetrics? metrics;
  String? metricsError;

  late WorkoutStepRecorder stepRecorder;
  final List<WorkoutStepResult> stepResults = [];

  int currentStepIndex = 0;
  late Duration remaining;

  bool running = false;
  bool finished = false;

  WorkoutStep get currentStep => widget.workout.steps[currentStepIndex];

  String resultPace(double seconds) {
    if (seconds <= 0) {
      return '--:--';
    }

    return formatPace(seconds.round());
  }

  String resultPower(double watts) {
    if (watts <= 0) {
      return '--';
    }

    return watts.round().toString();
  }

  String resultSpm(double spm) {
    if (spm <= 0) {
      return '--';
    }

    return spm.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    remaining = currentStep.duration;

    stepRecorder = WorkoutStepRecorder(currentStep);

    loadMetrics();

    metricsTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => loadMetrics(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    metricsTimer?.cancel();

    audioPlayer.dispose();
    WakelockPlus.disable();

    super.dispose();
  }

  Future<void> playCountdownSignal() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/countdown.wav'));
  }

  Future<void> playStepChangeSignal(WorkoutStepType type) async {
    await audioPlayer.stop();

    final sound = switch (type) {
      WorkoutStepType.work => 'sounds/work.wav',
      WorkoutStepType.recovery => 'sounds/recovery.wav',
      WorkoutStepType.cooldown => 'sounds/recovery.wav',
      WorkoutStepType.warmup => 'sounds/recovery.wav',
    };

    await audioPlayer.play(AssetSource(sound));
  }

  Future<void> playFinishedSignal() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/finished.wav'));
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

      if (remaining.inSeconds <= 3) {
        playCountdownSignal();
      }

      return;
    }

    nextStep(playSound: true);
  }

  void finishCurrentStep() {
    final completedDuration = currentStep.duration - remaining;

    stepResults.add(stepRecorder.finish(completedDuration));
  }

  void nextStep({bool playSound = false}) {
    timer?.cancel();

    finishCurrentStep();

    if (currentStepIndex >= widget.workout.steps.length - 1) {
      if (playSound) {
        playFinishedSignal();
      }

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
      stepRecorder = WorkoutStepRecorder(currentStep);
    });

    if (playSound) {
      playStepChangeSignal(currentStep.type);
    }

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

      if (running && result.smartRowReady) {
        stepRecorder.addSample(result);
      }

      setState(() {
        metrics = result;
        metricsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        metrics = null;
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

  Color powerColor(
    BuildContext context,
    WorkoutStep step,
    RowingMetrics metrics,
  ) {
    final min = step.targetPowerMin;
    final max = step.targetPowerMax;

    if (min == null || max == null || metrics.powerW == 0) {
      return Theme.of(context).colorScheme.onSurface;
    }

    final power = metrics.powerW.toDouble();

    if (power >= min && power <= max) {
      return Colors.green;
    }

    final deviation = power < min ? (min - power) / min : (power - max) / max;

    if (deviation <= 0.05) {
      return Colors.orange;
    }

    return Colors.red;
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

  Widget liveStatus(BuildContext context) {
    final isLive =
        metrics != null && metricsError == null && metrics!.smartRowReady;

    final statusText = metricsError != null
        ? 'Keine Verbindung'
        : metrics == null
        ? 'Verbinde …'
        : metrics!.smartRowReady
        ? 'LIVE'
        : metrics!.smartRowConnected
        ? 'SmartRow verbindet …'
        : 'SmartRow offline';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLive ? Icons.circle : Icons.circle_outlined,
          size: 12,
          color: isLive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(statusText, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }

  Widget stepResultCard(BuildContext context, WorkoutStepResult result) {
    final targetPercentage = result.targetPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.step.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              stepTypeLabel(result.step.type),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dauer'),
                Text(formatDuration(result.duration)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Leistung'),
                Text('${resultPower(result.averagePowerW)} W'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Schlagrate'),
                Text('${resultSpm(result.averageStrokeRateSpm)} SPM'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Pace'),
                Text('${resultPace(result.averagePace500mSeconds)} /500 m'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Distanz'), Text('${result.distanceM} m')],
            ),

            if (targetPercentage != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Im Zielbereich'),
                  Text(
                    '${targetPercentage.toStringAsFixed(0)} %',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Duration get totalResultDuration {
    return stepResults.fold(
      Duration.zero,
      (total, result) => total + result.duration,
    );
  }

  int get totalResultDistance {
    return stepResults.fold(0, (total, result) => total + result.distanceM);
  }

  double get totalAveragePower {
    var sum = 0.0;
    var samples = 0;

    for (final result in stepResults) {
      sum += result.averagePowerW * result.activePowerSamples;
      samples += result.activePowerSamples;
    }

    return samples == 0 ? 0 : sum / samples;
  }

  double get totalAverageStrokeRate {
    var weightedSum = 0.0;
    var weight = 0;

    for (final result in stepResults) {
      if (result.averageStrokeRateSpm > 0 && result.activePowerSamples > 0) {
        weightedSum += result.averageStrokeRateSpm * result.activePowerSamples;
        weight += result.activePowerSamples;
      }
    }

    return weight == 0 ? 0 : weightedSum / weight;
  }

  double get totalAveragePace {
    var weightedSum = 0.0;
    var weight = 0;

    for (final result in stepResults) {
      if (result.averagePace500mSeconds > 0 && result.activePowerSamples > 0) {
        weightedSum +=
            result.averagePace500mSeconds * result.activePowerSamples;
        weight += result.activePowerSamples;
      }
    }

    return weight == 0 ? 0 : weightedSum / weight;
  }

  double? get totalTargetPercentage {
    var inTarget = 0;
    var samples = 0;

    for (final result in stepResults) {
      if (!result.hasPowerTarget) {
        continue;
      }

      inTarget += result.samplesInTarget;
      samples += result.activePowerSamples;
    }

    if (samples == 0) {
      return null;
    }

    return inTarget / samples * 100;
  }

  Widget workoutSummaryCard(BuildContext context) {
    final targetPercentage = totalTargetPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Gesamt', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trainingszeit'),
                Text(formatDuration(totalResultDuration)),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Distanz'), Text('$totalResultDistance m')],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Leistung'),
                Text('${resultPower(totalAveragePower)} W'),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Schlagrate'),
                Text('${resultSpm(totalAverageStrokeRate)} SPM'),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ø Pace'),
                Text('${resultPace(totalAveragePace)} /500 m'),
              ],
            ),

            if (targetPercentage != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Im Zielbereich'),
                  Text(
                    '${targetPercentage.toStringAsFixed(0)} %',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget workoutResults(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Training abgeschlossen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.workout.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          workoutSummaryCard(context),

          const SizedBox(height: 24),

          Text('Abschnitte', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          for (final result in stepResults) ...[
            stepResultCard(context, result),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Training beenden'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: liveStatus(context)),
          ),
        ],
      ),
      body: finished
          ? workoutResults(context)
          : SafeArea(
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
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: powerColor(context, step, metrics!),
                            ),
                      ),
                      if (step.targetPowerMin != null &&
                          step.targetPowerMax != null) ...[
                        const SizedBox(height: 4),

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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Text('SPM'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                livePace(metrics!.pace500mSeconds),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const Text('/500 m'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${metrics!.distanceM}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                    if (step.targetSpmMin != null &&
                        step.targetSpmMax != null) ...[
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
                        onPressed: () => nextStep(),
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
