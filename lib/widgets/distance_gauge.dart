import 'package:flutter/material.dart';

import '../models/ranging_sample.dart';

class DistanceGauge extends StatelessWidget {
  const DistanceGauge({
    super.key,
    required this.latest,
    required this.recent,
  });

  final RangingSample? latest;
  final List<RangingSample> recent;

  ({double min, double max, double avg})? _stats() {
    if (recent.isEmpty) return null;
    var min = recent.first.distanceM;
    var max = min;
    var sum = 0.0;
    for (final s in recent) {
      if (s.distanceM < min) min = s.distanceM;
      if (s.distanceM > max) max = s.distanceM;
      sum += s.distanceM;
    }
    return (min: min, max: max, avg: sum / recent.length);
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats();
    final v = latest?.distanceM;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          v == null ? '—' : '${v.toStringAsFixed(2)} m',
          style: theme.textTheme.displayLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (s != null)
          DefaultTextStyle(
            style: theme.textTheme.labelMedium ?? const TextStyle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat('min', s.min),
                const SizedBox(width: 16),
                _stat('avg', s.avg),
                const SizedBox(width: 16),
                _stat('max', s.max),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stat(String label, double value) {
    return Column(
      children: [
        Text(label),
        Text(
          '${value.toStringAsFixed(2)} m',
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
