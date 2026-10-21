import 'package:flutter/material.dart';

class SystemStatusCard extends StatelessWidget {
  final bool running;
  final String activeMode;
  final bool smartRowConnected;
  final bool smartRowReady;

  const SystemStatusCard({
    super.key,
    required this.running,
    required this.activeMode,
    required this.smartRowConnected,
    required this.smartRowReady,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            _StatusLine(
              active: running,
              title: running ? 'PiRowFlo läuft' : 'PiRowFlo gestoppt',
              subtitle: activeMode,
            ),

            const SizedBox(height: 16),

            _StatusLine(
              active: smartRowReady,
              pending: smartRowConnected && !smartRowReady,
              title: smartRowReady
                  ? 'SmartRow verbunden'
                  : smartRowConnected
                  ? 'SmartRow verbindet …'
                  : 'SmartRow nicht verbunden',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final bool active;
  final bool pending;
  final String title;
  final String? subtitle;

  const _StatusLine({
    required this.active,
    required this.title,
    this.pending = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Colors.green
        : pending
        ? Colors.orange
        : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
