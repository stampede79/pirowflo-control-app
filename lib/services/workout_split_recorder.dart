import '../models/rowing_metrics.dart';
import '../models/workout_split.dart';

class WorkoutSplitRecorder {
  static const int splitDistanceM = 500;

  int? _previousDistanceM;
  int? _previousElapsedSeconds;
  int? _baseDistanceM;

  double _splitStartElapsedSeconds = 0;
  int _nextSplitDistanceM = splitDistanceM;

  double _powerSum = 0;
  int _powerSamples = 0;

  double _spmSum = 0;
  int _spmSamples = 0;

  double _heartRateSum = 0;
  int _heartRateSamples = 0;

  void reset() {
    _baseDistanceM = null;
    _previousDistanceM = null;
    _previousElapsedSeconds = null;

    _splitStartElapsedSeconds = 0;
    _nextSplitDistanceM = splitDistanceM;

    _resetAverages();
  }

  WorkoutSplit? addSample(RowingMetrics metrics, {int? heartRateBpm}) {
    final distance = metrics.distanceM;
    final elapsed = metrics.elapsedSeconds;

    if (_previousDistanceM == null || _previousElapsedSeconds == null) {
      _baseDistanceM = distance;
      _previousDistanceM = distance;
      _previousElapsedSeconds = elapsed;

      _splitStartElapsedSeconds = elapsed.toDouble();

      _nextSplitDistanceM = distance + splitDistanceM;

      _addAverages(metrics, heartRateBpm);

      return null;
    }

    // SmartRow wurde zurückgesetzt oder die Distanz
    // ist aus einem anderen Grund rückwärts gesprungen.
    if (distance < _previousDistanceM!) {
      reset();

      _baseDistanceM = distance;
      _previousDistanceM = distance;
      _previousElapsedSeconds = elapsed;

      _splitStartElapsedSeconds = elapsed.toDouble();

      _nextSplitDistanceM = distance + splitDistanceM;

      _addAverages(metrics, heartRateBpm);

      return null;
    }

    _addAverages(metrics, heartRateBpm);

    WorkoutSplit? completedSplit;

    if (distance >= _nextSplitDistanceM &&
        _previousDistanceM! < _nextSplitDistanceM) {
      final distanceDelta = distance - _previousDistanceM!;

      final elapsedDelta = elapsed - _previousElapsedSeconds!;

      final fraction = distanceDelta <= 0
          ? 1.0
          : (_nextSplitDistanceM - _previousDistanceM!) / distanceDelta;

      final splitEndElapsed =
          _previousElapsedSeconds! + elapsedDelta * fraction;

      final duration = splitEndElapsed - _splitStartElapsedSeconds;

      final workoutDistance = _nextSplitDistanceM - (_baseDistanceM ?? 0);

      completedSplit = WorkoutSplit(
        distanceM: workoutDistance,
        durationSeconds: duration < 0 ? 0 : duration,
        averagePowerW: _powerSamples == 0 ? 0 : _powerSum / _powerSamples,
        averageSpm: _spmSamples == 0 ? 0 : _spmSum / _spmSamples,
        averageHeartRateBpm: _heartRateSamples == 0
            ? null
            : _heartRateSum / _heartRateSamples,
      );

      _splitStartElapsedSeconds = splitEndElapsed;

      _nextSplitDistanceM += splitDistanceM;

      _resetAverages();
    }

    _previousDistanceM = distance;
    _previousElapsedSeconds = elapsed;

    return completedSplit;
  }

  void _addAverages(RowingMetrics metrics, int? heartRateBpm) {
    if (metrics.powerW > 0) {
      _powerSum += metrics.powerW;
      _powerSamples++;
    }

    if (metrics.strokeRateSpm > 0) {
      _spmSum += metrics.strokeRateSpm;
      _spmSamples++;
    }

    final heartRate =
        heartRateBpm ??
        (metrics.heartRateBpm > 0 ? metrics.heartRateBpm : null);

    if (heartRate != null && heartRate > 0) {
      _heartRateSum += heartRate;
      _heartRateSamples++;
    }
  }

  void _resetAverages() {
    _powerSum = 0;
    _powerSamples = 0;

    _spmSum = 0;
    _spmSamples = 0;

    _heartRateSum = 0;
    _heartRateSamples = 0;
  }
}
