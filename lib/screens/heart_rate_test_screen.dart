import 'dart:async';

import 'package:flutter/material.dart';

import '../services/heart_rate_service.dart';

class HeartRateTestScreen extends StatefulWidget {
  const HeartRateTestScreen({super.key});

  @override
  State<HeartRateTestScreen> createState() => _HeartRateTestScreenState();
}

class _HeartRateTestScreenState extends State<HeartRateTestScreen> {
  final HeartRateService _service = HeartRateService();

  StreamSubscription<int?>? _heartRateSubscription;
  StreamSubscription<String>? _statusSubscription;

  int? _heartRate;
  String _status = 'Noch nicht gestartet';

  @override
  void initState() {
    super.initState();

    _heartRateSubscription = _service.heartRate.listen((bpm) {
      if (!mounted) return;

      setState(() {
        _heartRate = bpm;
      });

      debugPrint('HRM: $bpm bpm');
    });

    _statusSubscription = _service.status.listen((status) {
      if (!mounted) return;

      setState(() {
        _status = status;
      });

      debugPrint('HRM status: $status');
    });

    _start();
  }

  Future<void> _start() async {
    setState(() {
      _heartRate = null;
      _status = 'Starte …';
    });

    await _service.start();
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _statusSubscription?.cancel();

    _service.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('HF-Sensor testen')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 64,
                        color: _heartRate != null
                            ? colors.primary
                            : colors.outline,
                      ),

                      const SizedBox(height: 24),

                      Text(
                        _heartRate?.toString() ?? '--',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),

                      Text(
                        'bpm',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: 28),

                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),

                      const SizedBox(height: 28),

                      FilledButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Neu verbinden'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
