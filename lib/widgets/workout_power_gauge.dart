import 'package:flutter/material.dart';

class WorkoutPowerGauge extends StatelessWidget {
  final double progress;
  final int powerW;
  final int? targetPowerMin;
  final int? targetPowerMax;
  final Color powerColor;
  final double size;

  const WorkoutPowerGauge({
    super.key,
    required this.progress,
    required this.powerW,
    required this.powerColor,
    this.targetPowerMin,
    this.targetPowerMax,
    this.size = 245,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetPowerMin != null && targetPowerMax != null;

    final scale = size / 245;

    final ringSize = 225 * scale;
    final innerSize = 180 * scale;
    final strokeWidth = 14 * scale;

    final powerStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 57 * scale,
      color: powerW > 0 ? powerColor : Theme.of(context).colorScheme.onSurface,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                powerW > 0 ? powerColor : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24 * scale,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(powerW > 0 ? '$powerW' : '--', style: powerStyle),
                Text(
                  'WATT',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 16 * scale, letterSpacing: 1.5),
                ),

                if (hasTarget) ...[
                  SizedBox(height: 10 * scale),
                  Text(
                    'Ziel '
                    '$targetPowerMin–'
                    '$targetPowerMax W',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 14 * scale),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const WorkoutMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
