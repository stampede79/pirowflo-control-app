import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/workout.dart';

import '../models/rowing_metrics.dart';
import '../services/metrics_service.dart';
import '../models/workout_step_result.dart';
import '../services/workout_step_recorder.dart';
import '../widgets/workout_power_gauge.dart';

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
    final values = <String>[formatDuration(result.duration)];

    if (result.averagePowerW > 0) {
      values.add('${resultPower(result.averagePowerW)} W');
    }

    if (result.averageStrokeRateSpm > 0) {
      values.add('${resultSpm(result.averageStrokeRateSpm)} SPM');
    }

    if (result.averagePace500mSeconds > 0) {
      values.add('${resultPace(result.averagePace500mSeconds)} /500 m');
    }

    if (result.distanceM > 0) {
      values.add('${result.distanceM} m');
    }

    return _ResultStep(
      title: result.step.title,
      subtitle: values.join(' · '),
      targetPercentage: result.targetPercentage,
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ResultMetric(
                icon: Icons.timer_outlined,
                value: formatDuration(totalResultDuration),
                label: 'Dauer',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ResultMetric(
                icon: Icons.straighten,
                value: '$totalResultDistance m',
                label: 'Distanz',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _ResultMetric(
                icon: Icons.bolt,
                value: '${resultPower(totalAveragePower)} W',
                label: 'Ø Leistung',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ResultMetric(
                icon: Icons.speed,
                value: '${resultSpm(totalAverageStrokeRate)} SPM',
                label: 'Ø Schlagrate',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _ResultMetric(
          icon: Icons.timer,
          value: '${resultPace(totalAveragePace)} /500 m',
          label: 'Ø Pace',
        ),

        if (targetPercentage != null) ...[
          const SizedBox(height: 12),

          _TargetResult(percentage: targetPercentage),
        ],
      ],
    );
  }

  Widget workoutResults(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 36),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Training abgeschlossen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 6),

          Text(
            widget.workout.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 30),

          workoutSummaryCard(context),

          const SizedBox(height: 34),

          Text('Abschnitte', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 18),

          for (var i = 0; i < stepResults.length; i++)
            _ResultTimelineEntry(
              showLine: i < stepResults.length - 1,
              child: stepResultCard(context, stepResults[i]),
            ),

          const SizedBox(height: 28),

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
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/rowing_background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),

                // Helles Overlay für gute Lesbarkeit beim Training.
                Container(
                  color: const Color(0xFFF2F9FB).withValues(alpha: 0.88),
                ),

                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          stepTypeLabel(step.type),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Abschnitt ${currentStepIndex + 1} von '
                          '${widget.workout.steps.length}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 28),

                        Center(
                          child: WorkoutPowerGauge(
                            progress: progress,
                            powerW: metrics?.smartRowReady == true
                                ? metrics!.powerW
                                : 0,
                            targetPowerMin: step.targetPowerMin,
                            targetPowerMax: step.targetPowerMax,
                            powerColor: metrics?.smartRowReady == true
                                ? powerColor(context, step, metrics!)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          formatDuration(remaining),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),

                        Text(
                          'verbleibend',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 26),

                        if (metrics != null && metrics!.smartRowReady)
                          Row(
                            children: [
                              WorkoutMetric(
                                icon: Icons.speed,
                                value: metrics!.strokeRateSpm > 0
                                    ? metrics!.strokeRateSpm.toStringAsFixed(0)
                                    : '--',
                                label: 'SPM',
                              ),

                              const SizedBox(width: 10),

                              WorkoutMetric(
                                icon: Icons.timer_outlined,
                                value: livePace(metrics!.pace500mSeconds),
                                label: '/500 m',
                              ),

                              const SizedBox(width: 10),

                              WorkoutMetric(
                                icon: Icons.straighten,
                                value: '${metrics!.distanceM}',
                                label: 'Meter',
                              ),
                            ],
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sensors_off,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Keine SmartRow-Livedaten',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
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

                        if (step.hasTargetPace ||
                            (step.targetSpmMin != null &&
                                step.targetSpmMax != null)) ...[
                          const SizedBox(height: 20),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Column(
                                children: [
                                  if (step.hasTargetPace)
                                    Text(
                                      'Zielpace: '
                                      '${formatPace(step.targetPaceMinSeconds!)}–'
                                      '${formatPace(step.targetPaceMaxSeconds!)} '
                                      '/500 m',
                                    ),

                                  if (step.hasTargetPace &&
                                      step.targetSpmMin != null &&
                                      step.targetSpmMax != null)
                                    const SizedBox(height: 6),

                                  if (step.targetSpmMin != null &&
                                      step.targetSpmMax != null)
                                    Text(
                                      'Schlagrate: '
                                      '${step.targetSpmMin}–'
                                      '${step.targetSpmMax} SPM',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (upcomingStep != null) ...[
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.skip_next_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Danach: ${upcomingStep.title} · '
                                  '${formatDuration(upcomingStep.duration)}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 28),

                        FilledButton.icon(
                          onPressed: running ? pause : start,
                          icon: Icon(running ? Icons.pause : Icons.play_arrow),
                          label: Text(running ? 'Pause' : 'Start / Fortsetzen'),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: () => nextStep(),
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Abschnitt überspringen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ResultMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetResult extends StatelessWidget {
  final double percentage;

  const _TargetResult({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.12),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)} %',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Im Zielbereich',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anteil der Leistungsmessungen innerhalb '
                    'des vorgegebenen Wattbereichs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? targetPercentage;

  const _ResultStep({
    required this.title,
    required this.subtitle,
    required this.targetPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          if (targetPercentage != null) ...[
            const SizedBox(height: 5),
            Text(
              '${targetPercentage!.toStringAsFixed(0)} % im Zielbereich',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultTimelineEntry extends StatelessWidget {
  final bool showLine;
  final Widget child;

  const _ResultTimelineEntry({required this.showLine, required this.child});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
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
