import 'package:flutter/material.dart';

import '../widgets/water_header.dart';

class ControlScreen extends StatelessWidget {
  final bool configured;
  final bool running;
  final String activeMode;

  final bool smartRowConnected;
  final bool smartRowReady;

  final String smartRowBluetoothStatusText;
  final bool smartRowBluetoothHealthy;
  final bool bluetoothRequired;

  final bool antAvailable;
  final bool antRequired;

  final bool loading;
  final String? error;

  final Map<String, String> states;

  final VoidCallback onSettings;
  final Future<void> Function(String path) onPost;

  const ControlScreen({
    super.key,
    required this.configured,
    required this.running,
    required this.activeMode,
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.smartRowBluetoothStatusText,
    required this.smartRowBluetoothHealthy,
    required this.bluetoothRequired,
    required this.antAvailable,
    required this.antRequired,
    required this.loading,
    required this.error,
    required this.states,
    required this.onSettings,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WaterHeader(
          height: 210,
          title: 'Steuerung',
          subtitle: 'PiRowFlo und SmartRow',
        ),

        Expanded(
          child: !configured
              ? Center(
                  child: FilledButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Verbindung einrichten'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Text(
                      'Betriebsmodus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: running
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                running
                                    ? Icons.check_circle_outline
                                    : Icons.power_settings_new,
                                color: running
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    running
                                        ? activeMode
                                        : 'Kein Betriebsmodus aktiv',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),

                                  if (running) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Aktiv',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Systemstatus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            _SystemStatusRow(
                              icon: Icons.rowing,
                              title: 'SmartRow',
                              status: smartRowReady
                                  ? 'Verbunden'
                                  : smartRowConnected
                                  ? 'Verbindung wird vorbereitet'
                                  : 'Nicht verbunden',
                              healthy: smartRowReady,
                            ),

                            const Divider(height: 1),

                            _SystemStatusRow(
                              icon: Icons.bluetooth,
                              title: 'Bluetooth',
                              status: smartRowBluetoothStatusText,
                              healthy: smartRowBluetoothHealthy,
                              warning:
                                  bluetoothRequired &&
                                  !smartRowBluetoothHealthy,
                            ),

                            const Divider(height: 1),

                            _SystemStatusRow(
                              icon: Icons.watch,
                              title: 'ANT+',
                              status: antAvailable
                                  ? 'Adapter erkannt'
                                  : 'Adapter nicht gefunden',
                              healthy: antAvailable,
                              warning: antRequired && !antAvailable,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (states['combined'] != 'RUNNING') ...[
                      FilledButton.icon(
                        onPressed: loading || states['combined'] == 'RUNNING'
                            ? null
                            : () => onPost('/api/start/combined'),
                        icon: Icon(
                          states['combined'] == 'RUNNING'
                              ? Icons.check_circle
                              : Icons.bluetooth_connected,
                        ),
                        label: Text(
                          states['combined'] == 'RUNNING'
                              ? 'BLE + ANT+ aktiv'
                              : 'BLE + ANT+ starten',
                        ),
                      ),

                      const SizedBox(height: 12),

                      FilledButton.tonalIcon(
                        onPressed: loading || states['bluetooth'] == 'RUNNING'
                            ? null
                            : () => onPost('/api/start/bluetooth'),
                        icon: Icon(
                          states['bluetooth'] == 'RUNNING'
                              ? Icons.check_circle
                              : Icons.bluetooth,
                        ),
                        label: Text(
                          states['bluetooth'] == 'RUNNING'
                              ? 'Bluetooth aktiv'
                              : 'Nur Bluetooth starten',
                        ),
                      ),

                      const SizedBox(height: 12),

                      FilledButton.tonalIcon(
                        onPressed: loading || states['ant'] == 'RUNNING'
                            ? null
                            : () => onPost('/api/start/ant'),
                        icon: Icon(
                          states['ant'] == 'RUNNING'
                              ? Icons.check_circle
                              : Icons.watch,
                        ),
                        label: Text(
                          states['ant'] == 'RUNNING'
                              ? 'ANT+ aktiv'
                              : 'Nur ANT+ starten',
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      onPressed: loading || !running
                          ? null
                          : () => onPost('/api/restart'),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Neu starten'),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: loading || !smartRowConnected || !smartRowReady
                          ? null
                          : () => onPost('/api/reset'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Training zurücksetzen'),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: loading || !running
                          ? null
                          : () => onPost('/api/stop'),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stoppen'),
                    ),

                    if (loading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SystemStatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool healthy;
  final bool warning;

  const _SystemStatusRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.healthy,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? Theme.of(context).colorScheme.error
        : healthy
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            warning
                ? Icons.warning_amber_rounded
                : healthy
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
