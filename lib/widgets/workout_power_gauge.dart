import 'package:flutter/material.dart';

class WorkoutPowerGauge extends StatelessWidget {
  final double progress;
  final int powerW;
  final int? targetPowerMin;
  final int? targetPowerMax;
  final Color powerColor;

  const WorkoutPowerGauge({
    super.key,
    required this.progress,
    required this.powerW,
    required this.powerColor,
    this.targetPowerMin,
    this.targetPowerMax,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetPowerMin != null && targetPowerMax != null;

    return SizedBox(
      width: 245,
      height: 245,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 225,
            height: 225,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                powerW > 0 ? powerColor : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  powerW > 0 ? '$powerW' : '--',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: powerW > 0
                        ? powerColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'WATT',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(letterSpacing: 1.5),
                ),

                if (hasTarget) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Ziel $targetPowerMin–$targetPowerMax W',
                    style: Theme.of(context).textTheme.bodyMedium,
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
