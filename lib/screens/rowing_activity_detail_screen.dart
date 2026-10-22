import 'package:flutter/material.dart';

import '../models/endurain_activity.dart';
import '../models/endurain_stream.dart';
import '../services/endurain_service.dart';
import '../widgets/rowing_stream_chart.dart';

class RowingActivityDetailScreen extends StatefulWidget {
  final EndurainActivity activity;
  final String endurainServer;

  const RowingActivityDetailScreen({
    super.key,
    required this.activity,
    required this.endurainServer,
  });

  @override
  State<RowingActivityDetailScreen> createState() =>
      _RowingActivityDetailScreenState();
}

class _RowingActivityDetailScreenState
    extends State<RowingActivityDetailScreen> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${duration.inMinutes}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String _formatPace(double seconds) {
    if (seconds <= 0) {
      return '--';
    }

    final rounded = seconds.round();
    final minutes = rounded ~/ 60;
    final secs = rounded % 60;

    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  List<EndurainStream> streams = [];
  bool streamsLoading = true;
  String? streamsError;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    try {
      final service = EndurainService(server: widget.endurainServer);

      final result = await service.getActivityStreams(widget.activity.id);

      if (!mounted) return;

      setState(() {
        streams = result;
        streamsLoading = false;
        streamsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        streamsLoading = false;
        streamsError = 'Verläufe konnten nicht geladen werden: $e';
      });
    }
  }

  EndurainStream? _stream(EndurainStreamType type) {
    for (final stream in streams) {
      if (stream.type == type) {
        return stream;
      }
    }

    return null;
  }

  DateTime? get _streamStart {
    DateTime? result;

    for (final stream in streams) {
      if (stream.points.isEmpty) {
        continue;
      }

      final start = stream.points.first.time;

      if (result == null || start.isBefore(result)) {
        result = start;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final powerStream = _stream(EndurainStreamType.power);
    final cadenceStream = _stream(EndurainStreamType.cadence);

    final heartRateStream = _stream(EndurainStreamType.heartRate);
    final streamStart = _streamStart;

    return Scaffold(
      appBar: AppBar(title: const Text('Rudertraining')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              widget.activity.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(widget.activity.startTime),
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: _DetailMetric(
                    value:
                        '${widget.activity.distanceKm.toStringAsFixed(2)} km',
                    label: 'Distanz',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetric(
                    value: _formatDuration(widget.activity.duration),
                    label: 'Dauer',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            _Section(
              title: 'Leistung',
              icon: Icons.bolt,
              children: [
                _ValueRow(
                  label: 'Ø Leistung',
                  value: '${widget.activity.averagePower.round()} W',
                ),
                _ValueRow(
                  label: 'Max. Leistung',
                  value: '${widget.activity.maxPower.round()} W',
                ),
                _ValueRow(
                  label: 'Normalized Power',
                  value: '${widget.activity.normalizedPower.round()} W',
                ),
              ],
            ),

            if (streamsLoading) ...[
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ] else if (streamsError != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    streamsError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ] else if (powerStream != null &&
                powerStream.points.isNotEmpty) ...[
              const SizedBox(height: 18),
              RowingStreamChart(
                stream: powerStream,
                title: 'Leistungsverlauf',
                unit: 'W',
                icon: Icons.bolt,
                edgeThreshold: 20,
                removeSpikes: true,
                useMedianFilter: true,
                chartStart: streamStart!,
                chartDuration: Duration(
                  seconds: widget.activity.duration.round(),
                ),
              ),
            ],

            const SizedBox(height: 18),

            _Section(
              title: 'Rudern',
              icon: Icons.rowing,
              children: [
                _ValueRow(
                  label: 'Ø Pace',
                  value:
                      '${_formatPace(widget.activity.pace500mSeconds)} /500 m',
                ),
                _ValueRow(
                  label: 'Ø Schlagrate',
                  value: '${widget.activity.averageCadence.round()} SPM',
                ),
                _ValueRow(
                  label: 'Max. Schlagrate',
                  value: '${widget.activity.maxCadence.round()} SPM',
                ),
                _ValueRow(
                  label: 'Schläge',
                  value: '${widget.activity.totalCycles}',
                ),
              ],
            ),
            if (cadenceStream != null && cadenceStream.points.isNotEmpty) ...[
              const SizedBox(height: 18),
              RowingStreamChart(
                stream: cadenceStream,
                title: 'Schlagratenverlauf',
                unit: 'SPM',
                icon: Icons.rowing,
                edgeThreshold: 3,
                removeSpikes: true,
                useMedianFilter: true,
                chartStart: streamStart!,
                chartDuration: Duration(
                  seconds: widget.activity.duration.round(),
                ),
              ),
            ],

            const SizedBox(height: 18),

            _Section(
              title: 'Herzfrequenz',
              icon: Icons.favorite_outline,
              children: [
                _ValueRow(
                  label: 'Durchschnitt',
                  value: '${widget.activity.averageHeartRate.round()} bpm',
                ),
                _ValueRow(
                  label: 'Maximum',
                  value: '${widget.activity.maxHeartRate.round()} bpm',
                ),
              ],
            ),
            if (heartRateStream != null &&
                heartRateStream.points.isNotEmpty) ...[
              const SizedBox(height: 18),
              RowingStreamChart(
                stream: heartRateStream,
                title: 'Herzfrequenzverlauf',
                unit: 'bpm',
                icon: Icons.favorite_outline,
                edgeThreshold: 40,
                removeSpikes: false,
                useMedianFilter: true,
                chartStart: streamStart!,
                chartDuration: Duration(
                  seconds: widget.activity.duration.round(),
                ),
              ),
            ],

            const SizedBox(height: 18),

            _Section(
              title: 'Energie',
              icon: Icons.local_fire_department_outlined,
              children: [
                _ValueRow(
                  label: 'Kalorien',
                  value: '${widget.activity.calories.round()} kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String value;
  final String label;

  const _DetailMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
